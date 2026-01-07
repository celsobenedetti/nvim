vim.g.supermaven = true
vim.g.autoformat = true
vim.g.completion = true
vim.g.eslint_autoformat = true
vim.g.incline = true
vim.g.dropbar = false

vim.o.background = 'dark'
vim.o.cmdheight = 0 -- Height of the command bar
vim.o.relativenumber = false

vim.g.env = require('config.env')
vim.g.dirs = require('config.dirs')
vim.g.colors = require('config.colors').default

vim.g.icons = {
  lsp = ' ',
  format = ' ',
  notes = ' ',
  git = {
    added = ' +',
    modified = ' ~',
    removed = ' -',
    branch = ' ',
    ahead = '',
    behind = '',
  },
  diagnostics = {
    error = ' ',
    warn = ' ',
    info = ' ',
    hint = ' ',
  },
  separator = {
    right = '  ',
    left = '  ',
  },
  dap = {
    breakpoint = '',
  },
}

vim.g.cmd = {
  git = {
    commits_ahead_of_origin = 'git rev-list --count HEAD ^origin/$(git branch --show-current)',
    commits_behind_origin = 'git rev-list --count ^HEAD origin/$(git branch --show-current)',
  },
}

vim.g.hl = {
  text = {
    highlight = 'Title',
    secondary = '@lsp.type.parameter.bash',
    subtext = 'Comment',
    warn = 'WarningMsg',
  },
  highlight = 'MiniStatuslineModeOther',
  warn = 'LspDiagnosticsVirtualTextWarning',
}

vim.g.ignore = {
  grep = {
    'pnpm-lock.yaml',
    'instascan.min.js',
  },
  explorer = {
    '*.org_archive',
  },
}

vim.g.web = {
  jira = vim.g.env.work.jira or '',
}

--- filsubtextetypes to close with q
vim.g.close_with_q = {
  'checkhealth',
  'dap-view',
  'dbout',
  'gitsigns-blame',
  'grug-far',
  'help',
  'lspinfo',
  'neotest-output',
  'neotest-output-panel',
  'neotest-summary',
  'notify',
  'PlenaryTestPopup',
  'qf',
  'spectre_panel',
  'startuptime',
  'tsplayground',
  'vim',
}

vim.g.treesitter = {
  -- filetypes to highlight with treesitter
  highlight = {
    'gitcommit',
    'go',
    'json',
    'html',
    'markdown',
    'typescript',
    'vue',
  },
}

--- check root file for specific stack
vim.g.root = {
  vue = 'vite.config.ts',
}

vim.g.statusline_show_position = false

-- Save swap file and trigger CursorHold
vim.opt.updatetime = 200
vim.opt.swapfile = false

vim.opt.tabstop = 4 -- Number of spaces tabs count for
vim.opt.shiftwidth = 4 -- Size of an indent - this seems to affect conform

vim.o.winborder = 'rounded'
vim.opt.spelllang = { 'en', 'pt' }
vim.o.spellcapcheck = ''
vim.opt.autowrite = true -- Enable auto write

-- only set clipboard if not in ssh, to make sure the OSC 52
-- integration works automatically.
vim.opt.clipboard = vim.env.SSH_CONNECTION and '' or 'unnamedplus' -- Sync with system clipboard
vim.opt.completeopt = 'menu,menuone,noselect'
vim.opt.conceallevel = 2 -- Hide * markup for bold and italic, but not markers with substitutions
vim.opt.confirm = true -- Confirm to save changes before exiting modified buffer
vim.opt.cursorline = true -- Enable highlighting of the current line
vim.opt.expandtab = true -- Use spaces instead of tabs
vim.opt.foldlevel = 99
vim.opt.foldmethod = 'indent'
vim.opt.foldtext = ''
-- vim.opt.formatexpr = "v:lua.LazyVim.format.formatexpr()"
vim.opt.formatoptions = 'jcroqlnt' -- tcqj
vim.opt.grepformat = '%f:%l:%c:%m'
vim.opt.grepprg = 'rg --vimgrep'
vim.opt.ignorecase = true -- Ignore case
vim.opt.inccommand = 'nosplit' -- preview incremental substitute
vim.opt.jumpoptions = 'view'
vim.opt.laststatus = 3 -- global statusline
vim.opt.linebreak = true -- Wrap lines at convenient points
vim.opt.list = true -- Show some invisible characters (tabs...
vim.opt.mouse = 'a' -- Enable mouse mode
vim.opt.number = true -- Print line number
vim.opt.pumblend = 10 -- Popup blend
vim.opt.pumheight = 10 -- Maximum number of entries in a popup
vim.opt.ruler = false -- Disable the default ruler
vim.opt.scrolloff = 4 -- Lines of context
vim.opt.sessionoptions = { 'buffers', 'curdir', 'tabpages', 'winsize', 'help', 'globals', 'skiprtp', 'folds' }
vim.opt.shiftround = true -- Round indent
vim.opt.shiftwidth = 2 -- Size of an indent
vim.opt.shortmess:append({ W = true, I = true, c = true, C = true })
vim.opt.showmode = false -- Dont show mode since we have a statusline
vim.opt.sidescrolloff = 8 -- Columns of context

vim.opt.signcolumn = 'yes' -- Always show the signcolumn, otherwise it would shift the text each time
vim.opt.smartcase = true -- Don't ignore case with capitals
vim.opt.smartindent = true -- Insert indents automatically
vim.opt.smoothscroll = true
vim.opt.spelllang = { 'en' }
vim.opt.splitbelow = true -- Put new windows below current
vim.opt.splitkeep = 'screen'
vim.opt.splitright = true -- Put new windows right of current
vim.opt.statuscolumn = [[%!v:lua.require('lib.utils').statuscolumn()]]
vim.opt.tabstop = 2 -- Number of spaces tabs count for
vim.opt.termguicolors = true -- True color support
vim.opt.timeoutlen = vim.g.vscode and 1000 or 300 -- Lower than default (1000) to quickly trigger which-key
vim.opt.undofile = true
vim.opt.undolevels = 10000
vim.opt.updatetime = 200 -- Save swap file and trigger CursorHold
vim.opt.virtualedit = 'block' -- Allow cursor to move where there is no text in visual block mode
vim.opt.wildmode = 'longest:full,full' -- Command-line completion mode
vim.opt.winminwidth = 5 -- Minimum window width
vim.opt.wrap = false -- Disable line wrap
