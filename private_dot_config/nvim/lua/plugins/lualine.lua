local function short_hostname()
  local fqdn = vim.uv.os_gethostname()
  local _, _, host = string.find(fqdn, "^(.-)%..*$")
  return host == nil and fqdn or host
end

return {
  {
    'nvim-lualine/lualine.nvim', -- Fancier statusline
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    opts = {
      options = {
        icons_enabled = true,
        --theme = 'gruvbox',
        theme = 'nord',
        component_separators = '|',
        section_separators = '',
        disabled_filetypes = {},
      },
      sections = {
        lualine_c = {
          'filename',
        },
        lualine_x = {
          {
            'diagnostics',
            sources = { "nvim_diagnostic" },
            symbols = {
              error = ' ',
              warn = ' ',
              info = ' ',
              hint = ' '
            }
          },
          'encoding',
          'filetype'
        },
        lualine_y = { 'progress' },
        lualine_z = { 'location', { short_hostname } }
      },
    },
  },
}
