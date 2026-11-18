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
  local hl = ({
    [vim.log.levels.ERROR] = "DiagnosticError",
    [vim.log.levels.WARN] = "DiagnosticWarn",
  })[level] or "DiagnosticInfo"
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

-- Render the current source file as chezmoi would write it to the target.
-- Unsaved edits of a .tmpl are rendered from the buffer; otherwise the saved source is used.
-- Returns the output, the target path and an optional warning about an inexact render.
local function render_target(buf)
  local file = normalize(vim.api.nvim_buf_get_name(buf))
  if not is_source_path(file) then return nil, "Not a chezmoi source file" end

  local target = vim.trim(vim.fn.system({ "chezmoi", "target-path", file }))
  if vim.v.shell_error ~= 0 then return nil, target end

  local out, warning
  if vim.bo[buf].modified and file:match("%.tmpl$") then
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    out = vim.fn.system({ "chezmoi", "execute-template" }, lines)
    -- execute-template knows nothing about the file it renders.
    if vim.fs.basename(file):match("^modify_") then
      warning = "Unsaved modify_ template: showing the rendered script, not the target. Save for the real result."
    elseif table.concat(lines, "\n"):find("%.chezmoi%.sourceFile") or table.concat(lines, "\n"):find("%.chezmoi%.targetFile") then
      warning = "Unsaved template uses .chezmoi.sourceFile/.chezmoi.targetFile, which are wrong here. Save for the real result."
    end
  else
    out = vim.fn.system({ "chezmoi", "cat", target })
  end
  if vim.v.shell_error ~= 0 then return nil, vim.trim(out) end
  return out, target, warning
end

vim.api.nvim_create_user_command("ChezmoiPreview", function()
  local out, target, warning = render_target(vim.api.nvim_get_current_buf())
  if not out then
    notify("chezmoi preview failed: " .. target, vim.log.levels.ERROR)
    return
  end
  if warning then notify(warning, vim.log.levels.WARN) end

  local name = "chezmoi://" .. target
  local buf = vim.fn.bufnr(name)
  if buf == -1 then
    buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(buf, name)
    vim.bo[buf].bufhidden = "wipe"
  end

  local lines = vim.split(out, "\n", { plain = true })
  if lines[#lines] == "" then table.remove(lines) end
  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].filetype = vim.filetype.match({ filename = target }) or ""

  if vim.fn.bufwinid(buf) == -1 then
    vim.cmd("vsplit")
    vim.api.nvim_win_set_buf(0, buf)
    vim.cmd("wincmd p")
  end
end, { desc = "Show the rendered chezmoi target of the current source file" })
