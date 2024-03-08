-- [[ Install `lazy.nvim` plugin manager ]]
local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not vim.loop.fs_stat(lazypath) then
  local lazyrepo = 'https://github.com/folke/lazy.nvim.git'
  vim.fn.system { 'git', 'clone', '--filter=blob:none', '--branch=stable', lazyrepo, lazypath }
end ---@diagnostic disable-next-line: undefined-field
vim.opt.rtp:prepend(lazypath)

vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

vim.g.have_nerd_font = true -- Set to true if you have a Nerd Font installed
vim.opt.number = true -- Make line numbers default
vim.opt.relativenumber = true

vim.opt.mouse = 'a' -- Enable mouse mode, can be useful for resizing splits for example!
vim.opt.showmode = false -- Don't show the mode, since it's already in status line

vim.opt.clipboard = 'unnamedplus' -- Sync clipboard between OS and Neovim.
vim.opt.breakindent = true -- Enable break indent
vim.opt.undofile = true -- Save undo history

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
vim.opt.scrolloff = 10 -- Minimal number of screen lines to keep above and below the cursor.

vim.opt.hlsearch = true -- Set highlight on search, but clear on pressing <Esc> in normal mode

--- Base keymaps

vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- Improve window/pane navigation
vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })
