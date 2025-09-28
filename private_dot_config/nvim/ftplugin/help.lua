vim.api.nvim_create_autocmd('BufWinEnter', {
    buffer = 0,
    callback = function(ev)
        -- Map F1 to close help only in help windows
        vim.keymap.set('n', '<F1>', ':close<CR>', { buffer = ev.buf, noremap = true, silent = true })
        -- Move window to far right
        vim.cmd('wincmd L')
        -- Set width to 80 columns
        vim.cmd('vertical resize 80')
    end,
})

vim.api.nvim_create_autocmd('BufWinLeave', {
    buffer = 0,
    callback = function()
        vim.keymap.set('n', '<F1>', '<F1>', { noremap = true })
    end,
})
