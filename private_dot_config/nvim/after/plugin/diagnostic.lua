local keymap = vim.keymap.set

vim.diagnostic.config({
  virtual_lines = false,
  virtual_text = false,
  underline = true,
  severity_sort = true,
  update_in_insert = true,
  float = {
    border = "rounded",
    source = "always",
    header = "",
    prefix = "",
  },
  jump = { float = true, wrap = false },
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = "✗",
      [vim.diagnostic.severity.WARN] = "▲",
      [vim.diagnostic.severity.INFO] = "∙",
      [vim.diagnostic.severity.HINT] = "∴"
    },
    severity = { min = vim.diagnostic.severity.HINT },
  },
})

keymap('n', 'td', function() vim.diagnostic.enable(not vim.diagnostic.is_enabled()) end, { desc = 'Toggle diagnostic' })

vim.cmd([[
set signcolumn=yes
autocmd CursorHold * lua vim.diagnostic.open_float(nil, { focusable = false })
]])
