local home = vim.fn.expand('~')
local o = vim.opt
o.keymap = 'russian-jcukenwin'
o.iminsert = 0
o.imsearch = 0

o.fileencoding = "utf-8"
o.pumheight = 10 --maximum items in popup
o.showmode = false
o.ignorecase = true
o.smartcase = true


o.termguicolors = true
o.guicursor = ""

o.syntax = 'on'


o.clipboard = "unnamedplus"

-- setlocal spell spelllang=ru_yo,en_us

o.tags = vim.opt.tags + (home .. "/.config/nvim/tags")
o.tags = vim.opt.tags + (home .. "/.local/nvim/nvim-linux64/share/nvim/runtime/doc/tags")

-- Ignore compiled files
o.wildignore = vim.opt.wildignore + { "*.o", "*~", "*.pyc", "*pycache*" }

-- Cool floating window popup menu for completion on command line
o.pumblend = 17
o.wildmode = "longest:full"
o.wildoptions = "pum"

o.winborder = "rounded"

-- Tabs
o.tabstop = 4
o.softtabstop = 4
o.shiftwidth = 4
o.expandtab = true
o.smartindent = true

-- o.inccommand = "split" -- creates window for incremental staff like %s/xxx/yyy to show changes
-- o.virtualedit = "block" -- change ctrl+v behavior and allow to select actually block with empty space

o.number = true
o.relativenumber = true
o.wrap = true   -- do not wrap line of text
o.hlsearch = false
o.hidden = true -- do not unload buffers, keep it in background
o.errorbells = false
o.swapfile = false
o.backup = false
o.undodir = (home .. '/.config/nvim/vim_undodir')
o.undofile = true
o.incsearch = true
o.scrolloff = 8
o.colorcolumn = '120'
o.signcolumn = 'yes'

-- vim.opt.listchars = {
--     eol='↵',
--     trail='~',
--     tab='>-',
--     nbsp='␣'
-- }
-- vim.opt.list = true

o.cmdheight = 1
o.updatetime = 50 -- default is 4000ms = 4s

o.mouse = 'a'

o.splitbelow = true
o.splitright = true

o.formatoptions = vim.opt.formatoptions
    - "a" -- Auto formatting is BAD.
    - "t" -- Don't auto format my code. I got linters for that.
    + "c" -- In general, I like it when comments respect textwidth
    + "q" -- Allow formatting comments w/ gq
    - "o" -- O and o, don't continue comments
    + "r" -- But do continue when pressing enter.
    + "n" -- Indent past the formatlistpat, not underneath it.
    + "j" -- Auto-remove comments if possible.
    - "2" -- I'm not in gradeschool anymore

local g = vim.g
g.mapleader = " "
g.maplocalleader = " "
-- FILE BROWSER:
g.netrw_banner = 0       -- disable banner
g.netrw_preview = 1      -- vertical split for preview
--g.netrw_altv = 1                -- open splits to the right
g.netrw_liststyle = 3    -- tree view
g.netrw_winsize = 30     -- use only 30% of screen for netrw
g.netrw_browse_split = 4 -- open in prev window
--g.netrw_list_hide = (vim.fn["netrw_gitignore#Hide"]()) .. [[,\(^\|\s\s\)\zs\.\S\+]], -- use .gitignore
-- check |netrw-browse-maps| for mappings

-- disable unused providers
g.loaded_ruby_provider = 0
g.loaded_perl_provider = 0
g.loaded_python_provider = 0
g.python3_host_prog = (home .. '/.local/venv/neovim/bin/python')
