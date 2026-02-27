-- Chezmoi integration: redirect managed files to source, auto-apply on save
if vim.fn.executable("chezmoi") ~= 1 then return end

local source_dir = vim.fn.expand("~/.local/share/chezmoi")
if vim.fn.isdirectory(source_dir) ~= 1 then return end

local managed_cache = nil

local function managed_files()
  if managed_cache then return managed_cache end
  managed_cache = {}
  local handle = io.popen("chezmoi managed --include=files --path-style=absolute 2>/dev/null")
  if handle then
    for line in handle:lines() do
      managed_cache[line] = true
    end
    handle:close()
  end
  return managed_cache
end

local function is_managed_buf(buf)
  local file = vim.api.nvim_buf_get_name(buf or 0)
  if file:find(source_dir, 1, true) then return true end
  return managed_files()[file] ~= nil
end

-- Expose for statusline
_G.chezmoi = {
  is_managed = function() return is_managed_buf(0) end,
  source_dir = source_dir,
}

local function notify(msg, level)
  local hl = level == vim.log.levels.ERROR and "DiagnosticError" or "DiagnosticInfo"
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { " " .. msg .. " " })
  vim.api.nvim_buf_add_highlight(buf, -1, hl, 0, 0, -1)
  local width = #msg + 2
  local win = vim.api.nvim_open_win(buf, false, {
    relative = "editor",
    anchor = "SE",
    row = vim.o.lines - 2,
    col = vim.o.columns,
    width = width,
    height = 1,
    style = "minimal",
    border = "rounded",
    focusable = false,
  })
  vim.defer_fn(function()
    if vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_close(win, true) end
    if vim.api.nvim_buf_is_valid(buf) then vim.api.nvim_buf_delete(buf, { force = true }) end
  end, 3000)
end

local group = vim.api.nvim_create_augroup("chezmoi", { clear = true })

vim.api.nvim_create_autocmd("BufReadPost", {
  group = group,
  desc = "Redirect chezmoi-managed files to their source",
  callback = function(ev)
    local file = vim.api.nvim_buf_get_name(ev.buf)
    if file:find(source_dir, 1, true) then return end
    if not managed_files()[file] then return end

    local result = vim.fn.system({ "chezmoi", "source-path", file })
    if vim.v.shell_error ~= 0 then return end
    local source = vim.trim(result)

    vim.schedule(function()
      vim.cmd("edit " .. vim.fn.fnameescape(source))
      vim.api.nvim_buf_delete(ev.buf, { force = true })
    end)
  end,
})

vim.api.nvim_create_autocmd("BufWritePost", {
  group = group,
  pattern = source_dir .. "/*",
  desc = "Auto-apply chezmoi on save",
  callback = function(ev)
    managed_cache = nil
    local result = vim.fn.system({ "chezmoi", "apply", "--source-path", ev.file })
    if vim.v.shell_error == 0 then
      notify("chezmoi apply ok", vim.log.levels.INFO)
    else
      notify("chezmoi apply failed: " .. vim.trim(result), vim.log.levels.ERROR)
    end
  end,
})

vim.api.nvim_create_user_command("ChezmoiRefresh", function()
  managed_cache = nil
  managed_files()
  notify("Chezmoi cache refreshed")
end, {})
