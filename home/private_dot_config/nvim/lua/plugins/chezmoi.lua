return {
  'htol/chezmoi.nvim',
  -- Local checkout for development; unset, lazy.nvim installs from GitHub.
  dir = vim.env.CHEZMOI_NVIM_DIR,
  lazy = false,
  opts = {},
}
