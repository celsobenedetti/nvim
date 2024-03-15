vim.g.mapleader = ' '
vim.g.maplocalleader = ' '
vim.g.autoformat = true

local opt = vim.opt

vim.g.have_nerd_font = true -- Set to true if you have a Nerd Font installed
opt.number = true -- Make line numbers default
opt.relativenumber = true
vim.o.conceallevel = 2

opt.mouse = 'a' -- Enable mouse mode, can be useful for resizing splits for example!
opt.showmode = false -- Don't show the mode, since it's already in status line

opt.clipboard = 'unnamedplus' -- Sync clipboard between OS and Neovim.
opt.breakindent = true -- Enable break indent
opt.undofile = true -- Save undo history
opt.spelllang = { 'en' }

opt.ignorecase = true -- Case-insensitive searching UNLESS \C or capital in search
opt.smartcase = true
opt.signcolumn = 'yes' -- Keep signcolumn on by default

opt.updatetime = 250 -- Decrease update time
opt.timeoutlen = 300

opt.splitright = true -- Configure how new splits should be opened
opt.splitbelow = true

opt.list = true -- Sets how neovim will display certain whitespace in the editor.
opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }

opt.inccommand = 'split' -- Preview substitutions live, as you type!
opt.cursorline = true -- Show which line your cursor is on
opt.scrolloff = 10 -- Minimal number of screen lines to keep above and below the cursor.

opt.hlsearch = true -- Set highlight on search, but clear on pressing <Esc> in normal mode

-- fold

opt.foldmethod = 'indent'
opt.foldlevel = 99
opt.fillchars = {
  foldopen = '',
  foldclose = '',
  fold = ' ',
  foldsep = ' ',
  diff = '╱',
  eob = ' ',
}

-- open buffers verticaly
vim.cmd 'autocmd FileType help wincmd L' --help
vim.cmd 'autocmd FileType man wincmd L' -- man
vim.cmd 'autocmd FileType Trouble wincmd L' -- man
