return {
  {
    "folke/lazydev.nvim",
    ft = "lua",
    opts = {
      library = {
        { path = "${3rd}/luv/library", words = { "vim%.uv" } },
      },
    },
  },
  {
    'neovim/nvim-lspconfig',
    dependencies = {
      { 'mason-org/mason.nvim', opts = {}, },
      -- {
      --   'mason-org/mason-lspconfig.nvim',
      --   opts = {
      --     automatic_enable = false,
      --     ensure_installed = {
      --       "lua_ls",
      --       "tailwindcss",
      --       "emmet_ls",
      --       "vue_ls",
      --       "ts_ls",
      --       "pyright",
      --       "ruff",
      --       "clangd",
      --       "gopls",
      --       "rust_analyzer",
      --       "yamlls",
      --       "jsonls",
      --       "terraformls",
      --     }, -- ensure_installed
      --   },   -- mason-lspconfig opts
      -- },     -- mason-lspconfig
      'saghen/blink.cmp',
      -- status updates for LSP.
      { 'j-hui/fidget.nvim',    opts = {} },
    }, -- dependencies

    config = function()
      --vim.lsp.set_log_level("debug")

      local capabilities = require('blink.cmp').get_lsp_capabilities()

      vim.lsp.config('*', {
        capabilities = capabilities,
      })

      vim.api.nvim_create_autocmd('LspAttach', {
        callback = function(args)
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          if not client then return end

          local map = function(keys, func, desc, mode)
            mode = mode or 'n'
            vim.keymap.set(mode, keys, func, { buffer = args.buf, desc = 'LSP: ' .. desc })
          end

          -- Rename the variable under your cursor.
          --  Most Language Servers support renaming across files, etc.
          map('grn', vim.lsp.buf.rename, '[R]e[n]ame')

          -- Execute a code action, usually your cursor needs to be on top of an error
          -- or a suggestion from your LSP for this to activate.
          map('gra', vim.lsp.buf.code_action, '[G]oto Code [A]ction', { 'n', 'x' })

          -- Find references for the word under your cursor.
          map('grr', require('telescope.builtin').lsp_references, '[G]oto [R]eferences')

          -- Jump to the implementation of the word under your cursor.
          --  Useful when your language has ways of declaring types without an actual implementation.
          map('gri', require('telescope.builtin').lsp_implementations, '[G]oto [I]mplementation')

          -- Jump to the definition of the word under your cursor.
          --  This is where a variable was first declared, or where a function is defined, etc.
          --  To jump back, press <C-t>.
          map('grd', require('telescope.builtin').lsp_definitions, '[G]oto [D]efinition')

          -- WARN: This is not Goto Definition, this is Goto Declaration.
          --  For example, in C this would take you to the header.
          map('grD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')

          -- Fuzzy find all the symbols in your current document.
          --  Symbols are things like variables, functions, types, etc.
          map('gO', require('telescope.builtin').lsp_document_symbols, 'Open Document Symbols')

          -- Fuzzy find all the symbols in your current workspace.
          --  Similar to document symbols, except searches over your entire project.
          map('gW', require('telescope.builtin').lsp_dynamic_workspace_symbols, 'Open Workspace Symbols')

          -- Jump to the type of the word under your cursor.
          --  Useful when you're not sure what type a variable is and you want to see
          --  the definition of its *type*, not where it was *defined*.
          map('grt', require('telescope.builtin').lsp_type_definitions, '[G]oto [T]ype Definition')
          if not client:supports_method('textDocument/willSaveWaitUntil')
              and client:supports_method('textDocument/formatting') then
            vim.api.nvim_create_autocmd('BufWritePre', {
              buffer = args.buf,
              callback = function()
                vim.lsp.buf.format({ bufnr = args.buf, id = client.id })
              end,
            }) -- BufWritePre
          end
        end,
      }) -- LspAttach autocmd


      vim.lsp.config('gopls', {
        cmd = { "gopls", "serve" },
        settings = {
          gopls = {
            experimentalPostfixCompletions = true,
            analyses = {
              unusedparams = true,
              shadow = true,
            },
            staticcheck = true,
            usePlaceholders = true,
            --linksInHover = false,
            codelenses = {
              generate = true,
              gc_details = true,
              regenerate_cgo = true,
              tidy = true,
              upgrade_dependency = true,
              vendor = true,
            },
          },
        },
      }) -- gopls
      vim.lsp.enable('gopls')

      --ts_ls = {},

      --local vue_ls_path = vim.fn.stdpath("data") .. "/mason/packages/vue-language-server/node_modules/@vue/language-server/"
      local tsdk_path = vim.fn.stdpath("data") .. "/mason/packages/vue-language-server/node_modules/typescript/lib"
      vim.lsp.config('vue_ls', {
        filetypes = { 'typescript', 'javascript', 'javascriptreact', 'typescriptreact', 'vue', 'json' },
        init_options = {
          vue = {
            hybridMode = false,
          },
          typescript = {
            tsdk = tsdk_path
          },
        },
      })
      vim.lsp.enable('vue_ls')

      vim.lsp.config('clangd', {
        root_dir = function() return vim.uv.cwd() end
      })
      vim.lsp.enable('clangd')

      vim.lsp.config('rust_analyzer', {
        settings = {
          ["rust-analyzer"] = {
            imports = {
              granularity = {
                group = "module",
              },
              prefix = "self",
            },
            cargo = {
              buildScripts = {
                enable = true,
              },
            },
            procMacro = {
              enable = true
            },
          }
        }
      })
      vim.lsp.enable('rust_analyzer')

      vim.lsp.config('lua_ls', {})
      vim.lsp.enable('lua_ls')

      vim.lsp.config('pyright', {})
      vim.lsp.enable('pyright')

      vim.lsp.config('ruff', {
        init_options = {
          settings = {
            -- Any extra CLI arguments for `ruff` go here.
            args = {},
          }
        }
      })
      vim.lsp.enable('ruff')

      --lsp.pylsp.setup{
      --  settings = {
      --    pylsp = {
      --      plugins = {
      --        pycodestyle = {
      --          ignore = {'W391'},
      --          maxLineLength = 88
      --        }
      --      }
      --    }
      --  }
      --}

      vim.lsp.config('yamlls', {})
      vim.lsp.enable('yamlls')

      vim.lsp.config('jsonls', {
        cmd = { "fnm", "exec", "--using=18", "vscode-json-languageserver" },
        commands = {
          Format = {
            function()
              vim.lsp.buf.range_formatting({}, { 0, 0 }, { vim.fn.line("$"), 0 })
            end
          }
        }
      })
      vim.lsp.enable('jsonls')

      vim.lsp.config('terraformls', {})
      vim.lsp.enable('terraformls')

      vim.lsp.config('emmet_ls', {
        filetypes = { 'html', 'htmldjango', 'typescriptreact', 'javascriptreact', 'css', 'sass', 'scss', 'less', 'vue' },
        init_options = {
          html = {
            options = {
              -- For possible options, see: https://github.com/emmetio/emmet/blob/master/src/config.ts#L79-L267
              ["bem.enabled"] = true,
            },
          },
        }
      })
      vim.lsp.enable('emmet_ls')
    end, -- config
  },
}
