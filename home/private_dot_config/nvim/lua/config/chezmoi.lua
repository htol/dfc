-- Chezmoi integration: redirect managed files to source, auto-apply on save
if vim.fn.executable("chezmoi") ~= 1 then return end

local function normalize(path)
  if not path or path == "" then return "" end
  return vim.fs.normalize(vim.fn.fnamemodify(path, ":p"))
end

local function detect_source_dir()
  local output = vim.fn.systemlist({ "chezmoi", "source-path" })
  if vim.v.shell_error ~= 0 or #output == 0 then return nil end

  local dir = normalize(output[1])
  if vim.fn.isdirectory(dir) ~= 1 then return nil end
  return dir
end

local source_dir = detect_source_dir()
if not source_dir then return end

local managed_cache = nil
local source_cache = {}

local function is_source_path(path)
  return vim.startswith(normalize(path), source_dir .. "/")
end

local function managed_files()
  if managed_cache then return managed_cache end
  managed_cache = {}
  local files = vim.fn.systemlist({ "chezmoi", "managed", "--include=files", "--path-style=absolute" })
  if vim.v.shell_error == 0 then
    for _, file in ipairs(files) do
      managed_cache[normalize(file)] = true
    end
  end
  return managed_cache
end

local function managed_patterns()
  return vim.tbl_keys(managed_files())
end

local function source_path(file)
  file = normalize(file)
  if source_cache[file] ~= nil then return source_cache[file] end

  local result = vim.fn.system({ "chezmoi", "source-path", file })
  if vim.v.shell_error ~= 0 then
    source_cache[file] = false
    return nil
  end

  local source = normalize(vim.trim(result))
  source_cache[file] = source
  return source
end

local function is_managed_buf(buf)
  local file = normalize(vim.api.nvim_buf_get_name(buf or 0))
  if is_source_path(file) then return true end
  return managed_files()[file] ~= nil
end

-- Expose for statusline
_G.chezmoi = {
  is_managed = function() return is_managed_buf(0) end,
  source_dir = source_dir,
}

local function notify(msg, level)
  local hl = level == vim.log.levels.ERROR and "DiagnosticError" or "DiagnosticInfo"
  local lines = {}
  for line in (msg .. "\n"):gmatch("(.-)\n") do
    table.insert(lines, " " .. line .. " ")
  end
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  for i = 0, #lines - 1 do
    vim.api.nvim_buf_add_highlight(buf, -1, hl, i, 0, -1)
  end
  local width = 0
  for _, l in ipairs(lines) do
    width = math.max(width, #l)
  end
  local win = vim.api.nvim_open_win(buf, false, {
    relative = "editor",
    anchor = "SE",
    row = vim.o.lines - 2,
    col = vim.o.columns,
    width = width,
    height = #lines,
    style = "minimal",
    border = "rounded",
    focusable = false,
  })
  vim.defer_fn(function()
    if vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_close(win, true) end
    if vim.api.nvim_buf_is_valid(buf) then vim.api.nvim_buf_delete(buf, { force = true }) end
  end, 3000)
end

local redirect_group = vim.api.nvim_create_augroup("chezmoi_redirect", { clear = true })
local apply_group = vim.api.nvim_create_augroup("chezmoi_apply", { clear = true })

local function switch_to_source_buffer(source, original_buf)
  local existing = vim.fn.bufnr(source)
  if existing > 0 and existing ~= original_buf then
    if vim.api.nvim_buf_is_loaded(existing) then
      vim.api.nvim_set_current_buf(existing)
      pcall(vim.api.nvim_buf_delete, original_buf, { force = true })
      return
    end

    pcall(vim.api.nvim_buf_delete, existing, { force = true })
  end

  vim.api.nvim_buf_set_name(original_buf, source)
  vim.cmd("silent noautocmd keepalt edit " .. vim.fn.fnameescape(source))
  vim.api.nvim_exec_autocmds("BufReadPost", { buffer = original_buf, modeline = true })
end

local function redirect_to_source(ev)
  local file = normalize(ev.file or vim.api.nvim_buf_get_name(ev.buf))
  if is_source_path(file) or not managed_files()[file] then return end

  local source = source_path(file)
  if not source then return end

  switch_to_source_buffer(source, ev.buf)
end

local function create_redirect_autocmds()
  vim.api.nvim_clear_autocmds({ group = redirect_group })

  local patterns = managed_patterns()
  if #patterns > 0 then
    vim.api.nvim_create_autocmd("BufReadCmd", {
      group = redirect_group,
      pattern = patterns,
      desc = "Open chezmoi-managed target files from their source",
      callback = redirect_to_source,
    })
  end

  vim.api.nvim_create_autocmd("BufReadPost", {
    group = redirect_group,
    desc = "Fallback redirect for chezmoi-managed target files",
    callback = function(ev)
      local file = normalize(vim.api.nvim_buf_get_name(ev.buf))
      if is_source_path(file) or not managed_files()[file] then return end

      local source = source_path(file)
      if not source then return end

      vim.schedule(function()
        if not vim.api.nvim_buf_is_valid(ev.buf) then return end
        vim.cmd("edit " .. vim.fn.fnameescape(source))
        pcall(vim.api.nvim_buf_delete, ev.buf, { force = true })
      end)
    end,
  })
end

local function create_apply_autocmd()
  vim.api.nvim_clear_autocmds({ group = apply_group })

  vim.api.nvim_create_autocmd("BufWritePost", {
    group = apply_group,
    pattern = source_dir .. "/*",
    desc = "Auto-apply chezmoi on save",
    callback = function(ev)
      managed_cache = nil
      source_cache = {}
      local file = normalize(vim.api.nvim_buf_get_name(ev.buf))
      local result = vim.fn.system({ "chezmoi", "apply", "--source-path", file })
      if vim.v.shell_error == 0 then
        notify("chezmoi apply ok", vim.log.levels.INFO)
      else
        notify("chezmoi apply failed: " .. vim.trim(result), vim.log.levels.ERROR)
      end
    end,
  })
end

create_redirect_autocmds()
create_apply_autocmd()

vim.api.nvim_create_user_command("ChezmoiRefresh", function()
  local detected = detect_source_dir()
  if not detected then
    notify("Chezmoi source dir not found", vim.log.levels.ERROR)
    return
  end

  source_dir = detected
  _G.chezmoi.source_dir = source_dir
  managed_cache = nil
  source_cache = {}
  managed_files()
  create_redirect_autocmds()
  create_apply_autocmd()
  notify("Chezmoi cache refreshed")
end, {})
