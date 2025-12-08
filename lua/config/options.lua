-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
--   /home/celso/local/lazyvim/lua/lazyvim/config/options.lua
-- Add any additional options here
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

vim.opt.spelllang = { 'en', 'pt' }
vim.g.completion = true
vim.g.performance = vim.g.performance or false
vim.o.winborder = 'rounded'
vim.o.relativenumber = false

vim.o.background = 'dark'
vim.g.noice = false
vim.g.bufferline = false
vim.g.dropbar = false
vim.g.smear_cursor = false
vim.g.snacks_animate = false
vim.g.origami = true

vim.g.scroll = false and not vim.g.performance
vim.g.supermaven_inline_completion = true

vim.g.trouble_lualine = false

vim.g.lualine = {
  enabled = true,
  lsp = false,
}

vim.g.ai = {
  models = {
    gpt = 'gpt-4.1',
  },
}

vim.g.animation_duration = 40
vim.g.delay = 80 -- delay used to accomodate for animations

vim.g.should_center = {
  on_n = true,
  on_gg = false,
  on_ctrl_d = true,
}

vim.g.grep_ignore = {
  'pnpm-lock.yaml',
  'instascan.min.js',
}

vim.g.web = {
  jira = os.getenv 'WORK_JIRA' or '',
}

vim.g.below_split_height = 0.5

-- Save swap file and trigger CursorHold
vim.opt.updatetime = 200
vim.opt.swapfile = false

vim.opt.tabstop = 4 -- Number of spaces tabs count for
vim.opt.shiftwidth = 4 -- Size of an indent - this seems to affect conform

vim.o.cmdheight = 1 -- Height of the command bar
vim.o.spellcapcheck = ''


vim.opt.autowrite = true -- Enable auto write
-- only set clipboard if not in ssh, to make sure the OSC 52
-- integration works automatically.
vim.opt.clipboard = vim.env.SSH_CONNECTION and "" or "unnamedplus" -- Sync with system clipboard
vim.opt.completeopt = "menu,menuone,noselect"
vim.opt.conceallevel = 2 -- Hide * markup for bold and italic, but not markers with substitutions
vim.opt.confirm = true -- Confirm to save changes before exiting modified buffer
vim.opt.cursorline = true -- Enable highlighting of the current line
vim.opt.expandtab = true -- Use spaces instead of tabs
vim.opt.foldlevel = 99
vim.opt.foldmethod = "indent"
vim.opt.foldtext = ""
-- vim.opt.formatexpr = "v:lua.LazyVim.format.formatexpr()"
vim.opt.formatoptions = "jcroqlnt" -- tcqj
vim.opt.grepformat = "%f:%l:%c:%m"
vim.opt.grepprg = "rg --vimgrep"
vim.opt.ignorecase = true -- Ignore case
vim.opt.inccommand = "nosplit" -- preview incremental substitute
vim.opt.jumpoptions = "view"
vim.opt.laststatus = 3 -- global statusline
vim.opt.linebreak = true -- Wrap lines at convenient points
vim.opt.list = true -- Show some invisible characters (tabs...
vim.opt.mouse = "a" -- Enable mouse mode
vim.opt.number = true -- Print line number
vim.opt.pumblend = 10 -- Popup blend
vim.opt.pumheight = 10 -- Maximum number of entries in a popup
vim.opt.ruler = false -- Disable the default ruler
vim.opt.scrolloff = 4 -- Lines of context
vim.opt.sessionoptions = { "buffers", "curdir", "tabpages", "winsize", "help", "globals", "skiprtp", "folds" }
vim.opt.shiftround = true -- Round indent
vim.opt.shiftwidth = 2 -- Size of an indent
vim.opt.shortmess:append({ W = true, I = true, c = true, C = true })
vim.opt.showmode = false -- Dont show mode since we have a statusline
vim.opt.sidescrolloff = 8 -- Columns of context
vim.opt.signcolumn = "yes" -- Always show the signcolumn, otherwise it would shift the text each time
vim.opt.smartcase = true -- Don't ignore case with capitals
vim.opt.smartindent = true -- Insert indents automatically
vim.opt.smoothscroll = true
vim.opt.spelllang = { "en" }
vim.opt.splitbelow = true -- Put new windows below current
vim.opt.splitkeep = "screen"
vim.opt.splitright = true -- Put new windows right of current
vim.opt.statuscolumn = [[%!v:lua.require('lib.snacks').statuscolumn()]]
vim.opt.tabstop = 2 -- Number of spaces tabs count for
vim.opt.termguicolors = true -- True color support
vim.opt.timeoutlen = vim.g.vscode and 1000 or 300 -- Lower than default (1000) to quickly trigger which-key
vim.opt.undofile = true
vim.opt.undolevels = 10000
vim.opt.updatetime = 200 -- Save swap file and trigger CursorHold
vim.opt.virtualedit = "block" -- Allow cursor to move where there is no text in visual block mode
vim.opt.wildmode = "longest:full,full" -- Command-line completion mode
vim.opt.winminwidth = 5 -- Minimum window width
vim.opt.wrap = false -- Disable line wrap
