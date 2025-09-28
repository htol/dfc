return {
  {
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdate',
    init = function(plugin)
      -- PERF: add nvim-treesitter queries to the rtp and it's custom query predicates early
      -- This is needed because a bunch of plugins no longer `require("nvim-treesitter")`, which
      -- no longer trigger the **nvim-treeitter** module to be loaded in time.
      -- Luckily, the only thins that those plugins need are the custom queries, which we make available
      -- during startup.
      require("lazy.core.loader").add_to_rtp(plugin)
      require("nvim-treesitter.query_predicates")
    end,
    config = function()
      require('nvim-treesitter.configs').setup {
        ensure_installed = {
          "go", "python", "rust", "bash", "html", "css", "javascript", "typescript",
          "json", "yaml", "toml", "lua", "vue",
          "sql", "query", "vim", "vimdoc"
        },

        auto_install = false,

        highlight = {
          enable = true,
          disable = function(lang, buf)
            local max_filesize = 100 * 1024 -- 100 KB
            local ok, stats = pcall(vim.uv.fs_stat, vim.api.nvim_buf_get_name(buf))
            if ok and stats and stats.size > max_filesize then
              return true
            end
          end,
          additional_vim_regex_highlighting = false,
        },

        incremental_selection = {
          enable = true,
          keymaps = {
            init_selection = "<M-w>",     -- maps in normal mode to init the node/scope selection
            node_incremental = "<M-w>",   -- increment to the upper named parent
            node_decremental = "<M-C-w>", -- decrement to the previous node
            scope_incremental = "<M-e>",  -- increment to the upper scope (as defined in locals.scm)
          },
        },

        textobjects = {
          lsp_interop = {
            enable = true,
            border = 'none',
            peek_definition_code = {
              ["<leader>pf"] = "@function.outer",
              ["<leader>pc"] = "@class.outer",
            }
          },

          select = {
            enable = true,
            -- Automatically jump forward to textobj, similar to targets.vim
            lookahead = true,
            keymaps = {
              -- You can use the capture groups defined in textobjects.scm
              ["af"] = "@function.outer",
              ["if"] = "@function.inner",

              ["ac"] = "@conditional.outer",
              ["ic"] = "@conditional.inner",

              ["aa"] = "@parameter.outer",
              ["ia"] = "@parameter.inner",

              ["av"] = "@variable.outer",
              ["iv"] = "@variable.inner",
            }
          },

          move = {
            enable = true,
            set_jumps = true,
            goto_next_start = {
              ["]p"] = "@parameter.inner",
              [']m'] = '@function.outer',
              [']]'] = '@class.outer',
            },
            goto_next_end = {
              [']M'] = '@function.outer',
              [']['] = '@class.outer',
            },
            goto_previous_start = {
              ["[p"] = "@parameter.inner",
              ['[m'] = '@function.outer',
              ['[['] = '@class.outer',
            },
            goto_previous_end = {
              ['[M'] = '@function.outer',
              ['[]'] = '@class.outer',
            }
          }
        },

        query_linter = {
          enable = true,
          use_virtual_text = true,
          lint_events = { "BufWrite", "CursorHold" },
        }
      }

      vim.keymap.set('n', '<leader>te', ':EditQuury<CR>', { desc = "treestitter live query editor" })
      vim.keymap.set('n', '<leader>ti', ':Inspect<CR>', { desc = "highllight capture group under cursor" })
    end
  },
  'nvim-treesitter/nvim-treesitter-textobjects',
}
