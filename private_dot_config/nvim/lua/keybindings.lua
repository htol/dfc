local map = vim.keymap.set

map("n", "<Space>", "<Nop>")
map("n", "-", "<CMD>Oil<CR>", { desc = "Open parent directory" })

map("n", "<Leader>W", ":w !sudo tee % > /dev/null")
map("n", "<Leader>w", ":w")
map("n", "<Leader><CR>", ":source %<cr>")

map("v", "<Leader>p", "\"_dP")
--vnoremap J :m '>+1<CR>gv=gv
--vnoremap K :m '<-2<CR>gv=gv

-- go to next/previous changes in diff and center the line on screen
local function navigate_change(direction)
  if vim.wo.diff then
    vim.cmd.normal({ direction == "next" and "]c" or "[c", bang = true })
  else
    require("gitsigns").nav_hunk(direction, { wrap = true })
  end
  vim.cmd.normal("zz")
end

map("n", "]c", function() navigate_change("next") end, { desc = "Next change/hunk" })
map("n", "[c", function() navigate_change("prev") end, { desc = "Previous change/hunk" })

map("n", "<F2>", ":Telescope<CR>")
map("n", "<F5>", ":w<CR>:make<CR>")

-- more centered views
-- zv - open folds
map("n", "n", "nzzzv")
map("n", "N", "Nzzzv")
map("n", "J", "mzJ`z")

-- copy from cursor position till eol
map("n", "Y", "y$")

-- Undo breakpoints in insert mode
map("i", ",", ",<c-g>u")
map("i", ".", ".<c-g>u")
map("i", "!", "!<c-g>u")
map("i", "?", "?<c-g>u")
map("i", "(", "(<c-g>u")
map("i", ")", ")<c-g>u")
map("i", "=", "=<c-g>u")

-- Jumplist mutations
map("n", "k", "(v:count > 5 ? \"m'\" . v:count : \"\") . 'k'", { expr = true })
map("n", "j", "(v:count > 5 ? \"m'\" . v:count : \"\") . 'j'", { expr = true })

-- Moving text. Line or selection
map("v", "<C-j>", ":m '>+1<CR>gv=gv")
map("v", "<C-k", ":m '<-2<CR>gv=gv")
map("i", "<C-j>", ":m .+1<CR>gv=gv")
map("i", "<C-k>", ":m .-2<CR>gv=gv")
map("n", "<C-j>", ":m .+1<CR>gv=gv")
map("n", "<C-k>", ":m .-2<CR>gv=gv")

map("v", "<", "<gv", { desc = "Indent left and reselect" })
map("v", ">", ">gv", { desc = "Indent right and reselect" })

-- switch keyboard layouts by C-F instead of C-^
map({ "c", "n", "i", "v" }, "<C-f>", "<C-^>", { remap = true, silent = true })

map("n", "<leader>pa", function()
  local path = vim.fn.expand("%:p")
  vim.fn.setreg("+", path)
end, {desc="Copy full file path"})

-- In WSL copy to windows clipboard via clip.exe
-- TODO: implement in lua
--func! GetSelectedText()
--    normal gv"xy
--    let result = getreg("x")
--    return result
--endfunc
--
--if !has("clipboard") && executable("clip.exe")
--    noremap <C-C> :call system('clip.exe', GetSelectedText())<CR>
--    noremap <C-X> :call system('clip.exe', GetSelectedText())<CR>gvx
--endif
