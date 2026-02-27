local map = vim.keymap.set
local file_ignore_patterns = {
  '.git/', '.venv', 'venv',
  'node_modules', 'vim_undodir/', 'repo.git', 'plugged',
  'google-chrome/', 'BraveSoftware/', 'discord/', 'go/',
}

local search_dotfiles = function()
  require("telescope.builtin").find_files({
    prompt_title = "< files in .config >",
    cwd = "~/.config/",
    file_ignore_patterns = file_ignore_patterns
  })
end

return {
  {
    {
      'nvim-telescope/telescope.nvim',
      dependencies = {
        'nvim-lua/popup.nvim',
        'nvim-lua/plenary.nvim',
        'nvim-telescope/telescope-ui-select.nvim',
        { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
      },
      config = function()
        require('telescope').setup({
          extensions = {
            ['fzf'] = { fuzzy = true, override_generic_sorter = true, override_file_sorter = true, case_mode = 'smart_case' },
            ['ui-select'] = { require('telescope.themes').get_dropdown() }
          },
          pickers = {
            find_files = {
              theme = "ivy",
              mappings = {
                i = {
                  ["<C-u>"] = function(prompt_bufnr)
                    -- cwd is only set if passed as telescope option
                    local current_picker = require("telescope.actions.state").get_current_picker(prompt_bufnr)
                    local cwd = current_picker.cwd and tostring(current_picker.cwd) or vim.loop.cwd()
                    local parent_dir = vim.fs.dirname(cwd)

                    require("telescope.actions").close(prompt_bufnr)
                    require("telescope.builtin").find_files {
                      prompt_title = vim.fs.basename(parent_dir),
                      cwd = parent_dir,
                    }
                  end,
                },
              },
            },
          },
          vimgrep_argument = { 'rg', '--smart-case' }
        })

        require 'telescope'.load_extension('fzf')
        require 'telescope'.load_extension('ui-select')

        local builtin = require("telescope.builtin")
        map("n", "<leader>uc", function() builtin.colorscheme({ enable_preview = true }) end,
          { noremap = true, silent = true, desc = "Change colorscheme" })
        map("n", "<Leader>ps", function() builtin.grep_string({ search = vim.fn.input("Grep for > ") }) end)
        map("n", "<leader>ff",
          function() builtin.find_files({ hidden = true, file_ignore_patterns = file_ignore_patterns }) end,
          { desc = "Telescope find file" })
        map("n", "<leader>fr", search_dotfiles, { desc = "Telescope select dotfile" })
        map("n", "<leader>fg", builtin.live_grep, { desc = "Telescope live grep" })
        map("n", "<leader>fb", builtin.buffers, { desc = "Telescope show opened buffers" })
        map("n", "<leader>fh", builtin.help_tags, { desc = "Telescope help tags" })
        map("n", "<leader>fx", builtin.resume, { noremap = true, silent = true, desc = "Resume last picker" })
      end
    },
  },
}
