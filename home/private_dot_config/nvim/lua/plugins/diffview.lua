return {
    {
        'sindrets/diffview.nvim',
        cmd = { 'DiffviewOpen', 'DiffviewFileHistory' },
        keys = {
            { '<leader>gd', '<cmd>DiffviewFileHistory<cr>', desc = 'Git history (diffview)' },
        },
    },
}
