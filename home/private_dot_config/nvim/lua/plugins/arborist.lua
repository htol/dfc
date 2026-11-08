-- Tree-sitter parsers and queries for Neovim 0.12+ (replaces the archived
-- nvim-treesitter). Arborist also starts highlighting and indentation.
return {
  {
    'arborist-ts/arborist.nvim',
    lazy = false,
    opts = {
      -- This Neovim build has no wasmtime; skip the ~1 GB WASM toolchain download.
      prefer_wasm = false,
      install_popular = false,
      ensure_installed = {
        "go", "python", "rust", "bash", "html", "css", "javascript", "typescript",
        "json", "yaml", "toml", "lua", "vue",
        "sql", "query", "vim", "vimdoc",
      },
    },
    config = function(_, opts)
      require('arborist').setup(opts)

      -- Old incremental selection keys on top of the built-in an/in.
      vim.keymap.set('n', '<M-w>', 'van', { remap = true, desc = "Start Tree-sitter node selection" })
      vim.keymap.set('x', '<M-w>', 'an', { remap = true, desc = "Expand Tree-sitter node selection" })
      vim.keymap.set('x', '<M-C-w>', 'in', { remap = true, desc = "Shrink Tree-sitter node selection" })

      vim.keymap.set('n', '<leader>te', '<cmd>EditQuery<CR>', { desc = "Tree-sitter live query editor" })
      vim.keymap.set('n', '<leader>ti', '<cmd>Inspect<CR>', { desc = "Highlight capture group under cursor" })
    end,
  },
  {
    'nvim-treesitter/nvim-treesitter-textobjects',
    branch = 'main',
    lazy = false,
    opts = {
      select = { lookahead = true },
      move = { set_jumps = true },
    },
    config = function(_, opts)
      require('nvim-treesitter-textobjects').setup(opts)

      local select = require('nvim-treesitter-textobjects.select')
      for key, capture in pairs {
        af = "@function.outer", ["if"] = "@function.inner",
        ac = "@conditional.outer", ic = "@conditional.inner",
        aa = "@parameter.outer", ia = "@parameter.inner",
        av = "@variable.outer", iv = "@variable.inner",
      } do
        vim.keymap.set({ 'x', 'o' }, key, function()
          select.select_textobject(capture, "textobjects")
        end, { desc = "Select " .. capture })
      end

      local move = require('nvim-treesitter-textobjects.move')
      for key, m in pairs {
        [']p'] = { move.goto_next_start, "@parameter.inner" },
        [']m'] = { move.goto_next_start, "@function.outer" },
        [']]'] = { move.goto_next_start, "@class.outer" },
        [']M'] = { move.goto_next_end, "@function.outer" },
        [']['] = { move.goto_next_end, "@class.outer" },
        ['[p'] = { move.goto_previous_start, "@parameter.inner" },
        ['[m'] = { move.goto_previous_start, "@function.outer" },
        ['[['] = { move.goto_previous_start, "@class.outer" },
        ['[M'] = { move.goto_previous_end, "@function.outer" },
        ['[]'] = { move.goto_previous_end, "@class.outer" },
      } do
        vim.keymap.set({ 'n', 'x', 'o' }, key, function()
          m[1](m[2], "textobjects")
        end, { desc = "Move to " .. m[2] })
      end
    end,
  },
}
