return{
    -- {
    --     'gruvbox-community/gruvbox',
    --     config = function()
    --         --         --vim.cmd('colorscheme gruvbox')
    --         --         --vim.opt.background='dark'
    --         vim.cmd('highlight Normal guibg=none') -- for transparent background
    --     end
    -- },
    -- {'catppuccin/nvim', name="catppuccin"},
    -- {'LunarVim/lunar.nvim'},
    {
        "shaunsingh/nord.nvim",
        lazy = false,
        priority = 1000,
        config = function()
            vim.cmd.colorscheme "nord"
            -- vim.cmd('highlight Normal guibg=none') -- for transparent background
        end,
    },
}
