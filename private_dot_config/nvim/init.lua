require('globals')
require('options')
require('config.lazy')
require('keybindings')

vim.api.nvim_create_autocmd("TextYankPost", {
  desc = "Highlight when yanking (copying) text",
  group = vim.api.nvim_create_augroup("kickstart-highlight-yank", { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})

--if has("autocmd")
--  filetype plugin indent on
--endif
--
--function! Tabline()
--  let s = ''
--  for i in range(tabpagenr('$'))
--    let tab = i + 1
--    let winnr = tabpagewinnr(tab)
--    let buflist = tabpagebuflist(tab)
--    let bufnr = buflist[winnr - 1]
--    let bufname = bufname(bufnr)
--    let bufmodified = getbufvar(bufnr, "&mod")
--
--    let s .= '%' . tab . 'T'
--    let s .= (tab == tabpagenr() ? '%#TabLineSel#' : '%#TabLine#')
--    let s .= ' ' . tab .':'
--    let s .= (bufname != '' ? '['. fnamemodify(bufname, ':t') . '] ' : '[No Name] ')
--
--    if bufmodified
--      let s .= '[+] '
--    endif
--  endfor
--
--  let s .= '%#TabLineFill#'
--  if (exists("g:tablineclosebutton"))
--    let s .= '%=%999XX'
--  endif
--  return s
--endfunction
--set tabline=%!Tabline()
--
--" TAG JUMPING:
--command! MakeTags !ctags -R .
--" NOW WE CAN:
--" - Use ^] to jump to tag under cursor
--" - Use g^] for ambiguous tags
--" - Use ^t to jump back up the tag stack
--
--
--autocmd BufNewFile * silent! 0r $HOME/.config/nvim/templates/%:e.tpl
