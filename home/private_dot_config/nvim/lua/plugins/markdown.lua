-- In-buffer markdown rendering (headings, tables, checkboxes, callouts,
-- code blocks). Text-only via treesitter extmarks, so it works in Neovide.
-- Inline images are NOT possible in Neovide yet: image.nvim needs a
-- kitty/sixel/ueberzug backend which Neovide does not implement,
-- see neovide/neovide#2088.
return {
  {
    'MeanderingProgrammer/render-markdown.nvim',
    dependencies = { { 'echasnovski/mini.icons', opts = {} } },
    ft = { 'markdown' },
    opts = {},
  },
}
