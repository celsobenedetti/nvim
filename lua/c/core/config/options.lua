vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- defaults
vim.g.autoformat = true
vim.g.copilot = false
vim.g.completion = false
vim.g.diagnostics = true

vim.opt.background = 'dark'
vim.g.code_colorscheme = 'default'
vim.g.pretty_colorscheme = 'catppuccin-mocha'

vim.g.have_nerd_font = true -- Set to true if you have a Nerd Font installed

local opt = vim.opt

opt.number = true -- Make line numbers default
opt.relativenumber = true
opt.conceallevel = 2

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

-- LazyVim

opt.autowrite = true -- Enable auto write
opt.clipboard = 'unnamedplus' -- Sync with system clipboard
opt.completeopt = 'menu,menuone,noselect'
opt.confirm = true -- Confirm to save changes before exiting modified buffer
opt.cursorline = true -- Enable highlighting of the current line
opt.expandtab = true -- Use spaces instead of tabs
opt.formatoptions = 'jcroqlnt' -- tcqj
opt.grepformat = '%f:%l:%c:%m'
opt.grepprg = 'rg --vimgrep'
opt.ignorecase = true -- Ignore case
opt.inccommand = 'nosplit' -- preview incremental substitute
opt.laststatus = 3 -- global statusline
opt.list = true -- Show some invisible characters (tabs...
opt.mouse = 'a' -- Enable mouse mode
opt.number = true -- Print line number
opt.pumblend = 10 -- Popup blend
opt.pumheight = 10 -- Maximum number of entries in a popup
opt.relativenumber = true -- Relative line numbers
opt.scrolloff = 4 -- Lines of context
opt.sessionoptions = { 'buffers', 'curdir', 'tabpages', 'winsize', 'help', 'globals', 'skiprtp', 'folds' }
opt.shiftround = true -- Round indent
opt.shiftwidth = 2 -- Size of an indent
opt.shortmess:append { W = true, I = true, c = true, C = true }
opt.showmode = false -- Dont show mode since we have a statusline
opt.sidescrolloff = 8 -- Columns of context
opt.signcolumn = 'yes' -- Always show the signcolumn, otherwise it would shift the text each time
opt.smartcase = true -- Don't ignore case with capitals
opt.smartindent = true -- Insert indents automatically
opt.spelllang = { 'en' }
opt.splitbelow = true -- Put new windows below current
opt.splitkeep = 'screen'
opt.splitright = true -- Put new windows right of current
opt.tabstop = 2 -- Number of spaces tabs count for
opt.termguicolors = true -- True color support
if not vim.g.vscode then
  opt.timeoutlen = 300 -- Lower than default (1000) to quickly trigger which-key
end
opt.undofile = true
opt.undolevels = 10000
opt.updatetime = 200 -- Save swap file and trigger CursorHold
opt.virtualedit = 'block' -- Allow cursor to move where there is no text in visual block mode
opt.wildmode = 'longest:full,full' -- Command-line completion mode
opt.winminwidth = 5 -- Minimum window width
opt.wrap = false -- Disable line wrap
opt.fillchars = {
  foldopen = '',
  foldclose = '',
  -- fold = "⸱",
  fold = ' ',
  foldsep = ' ',
  diff = '╱',
  eob = ' ',
}

if vim.fn.has 'nvim-0.10' == 1 then
  opt.smoothscroll = true
end
