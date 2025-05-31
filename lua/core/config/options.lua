vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

vim.opt.background = C.ui.background

vim.opt.number = true -- Make line numbers default
vim.opt.relativenumber = true
vim.opt.conceallevel = 2

-- Lines of context config
-- Used to determine the min number of lines above/below the cursor, and thus when to trigger scrolling
vim.opt.scrolloff = 20

vim.opt.mouse = 'a' -- Enable mouse mode, can be useful for resizing splits for example!
vim.opt.showmode = false -- Don't show the mode, since it's already in status line

vim.opt.clipboard = 'unnamedplus' -- Sync clipboard between OS and Neovim.
vim.opt.breakindent = true -- Enable break indent
vim.opt.undofile = true -- Save undo history
vim.opt.spelllang = { 'en' }

vim.opt.ignorecase = true -- Case-insensitive searching UNLESS \C or capital in search
vim.opt.smartcase = true
vim.opt.signcolumn = 'yes' -- Keep signcolumn on by default

vim.opt.updatetime = 250 -- Decrease update time
vim.opt.timeoutlen = 300

vim.opt.splitright = true -- Configure how new splits should be opened
vim.opt.splitbelow = true

vim.opt.list = true -- Sets how neovim will display certain whitespace in the editor.
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }

vim.opt.inccommand = 'split' -- Preview substitutions live, as you type!
vim.opt.cursorline = true -- Show which line your cursor is on

-- fold

vim.opt.foldmethod = 'indent'
-- vim.opt.foldlevel = 99
vim.o.foldcolumn = '1' -- '0' is not bad
vim.o.foldlevel = 99 -- Using ufo provider need a large value, feel free to decrease the value
vim.o.foldlevelstart = 99
vim.o.foldenable = true
-- vim.opt.foldlevelstart = 99
-- vim.opt.fillchars = {
--   foldopen = '',
--   foldclose = '',
--   fold = ' ',
--   foldsep = ' ',
--   diff = '╱',
--   eob = ' ',
-- }

-- open buffers verticaly
vim.cmd 'autocmd FileType help wincmd L' --help
vim.cmd 'autocmd FileType man wincmd L' -- man
vim.cmd 'autocmd FileType Trouble wincmd L' -- man

-- LazyVim

vim.opt.autowrite = true -- Enable auto write
vim.opt.clipboard = 'unnamedplus' -- Sync with system clipboard
vim.opt.completeopt = 'menu,menuone,noselect'
vim.opt.confirm = true -- Confirm to save changes before exiting modified buffer
vim.opt.cursorline = true -- Enable highlighting of the current line
vim.opt.expandtab = true -- Use spaces instead of tabs
vim.opt.formatoptions = 'jcroqlnt' -- tcqj
vim.opt.grepformat = '%f:%l:%c:%m'
vim.opt.grepprg = 'rg --vimgrep'
vim.opt.ignorecase = true -- Ignore case
vim.opt.inccommand = 'nosplit' -- preview incremental substitute
vim.opt.laststatus = 3 -- global statusline
vim.opt.list = true -- Show some invisible characters (tabs...
vim.opt.mouse = 'a' -- Enable mouse mode
vim.opt.number = true -- Print line number
vim.opt.pumblend = 10 -- Popup blend
vim.opt.pumheight = 10 -- Maximum number of entries in a popup
vim.opt.relativenumber = true -- Relative line numbers

vim.opt.sessionoptions = { 'buffers', 'curdir', 'tabpages', 'winsize', 'help', 'globals', 'skiprtp', 'folds' }
vim.opt.shiftround = true -- Round indent
vim.opt.shiftwidth = 2 -- Size of an indent
vim.opt.shortmess:append { W = true, I = true, c = true, C = true }
vim.opt.showmode = false -- Dont show mode since we have a statusline
vim.opt.sidescrolloff = 8 -- Columns of context
vim.opt.signcolumn = 'yes' -- Always show the signcolumn, otherwise it would shift the text each time
vim.opt.smartcase = true -- Don't ignore case with capitals
vim.opt.smartindent = true -- Insert indents automatically
vim.opt.spelllang = { 'en' }
vim.opt.splitbelow = true -- Put new windows below current
vim.opt.splitkeep = 'screen'
vim.opt.splitright = true -- Put new windows right of current
vim.opt.tabstop = 4 -- Number of spaces tabs count for
vim.opt.termguicolors = true -- True color support
if not vim.g.vscode then
  vim.opt.timeoutlen = 300 -- Lower than default (1000) to quickly trigger which-key
end
vim.opt.undofile = true
vim.opt.undolevels = 10000
vim.opt.updatetime = 200 -- Save swap file and trigger CursorHold
vim.opt.swapfile = false

vim.opt.virtualedit = 'block' -- Allow cursor to move where there is no text in visual block mode
vim.opt.wildmode = 'longest:full,full' -- Command-line completion mode
vim.opt.winminwidth = 20 -- Minimum window width
vim.opt.wrap = false -- Disable line wrap
vim.opt.fillchars = {
  foldopen = '',
  foldclose = '',
  -- fold = "⸱",
  fold = ' ',
  foldsep = ' ',
  diff = '╱',
  eob = ' ',
}

if vim.fn.has 'nvim-0.10' == 1 then
  vim.opt.smoothscroll = true
end
