state.lsp = true
state.supermaven = true
state.autoformat = true
state.completion = true
state.eslint_autoformat = true
state.incline = false
state.statusline = true

vim.o.cmdheight = 1    -- Height of the command bar
vim.o.relativenumber = false
state.colorcolumn = 80 -- column highlighted by the colorcolumn toggle (<leader>u|)

state.env = {
  WORK = os.getenv('WORK') or '',
  work = {
    jira = os.getenv('WORK_JIRA') or '',
  },
  JIRA_API_TOKEN = os.getenv('JIRA_API_TOKEN') or '',

  HOME = os.getenv('HOME') or '',
  quartz = 'http://localhost:42069',

  notes = {
    NOTES = os.getenv('NOTES') or '',
    OBSIDIAN_VAULT = os.getenv('OBSIDIAN_VAULT') or '',
    OBSIDIAN_VAULT_WORK = os.getenv('OBSIDIAN_VAULT_WORK') or '',
    OBSIDIAN_INBOX = os.getenv('OBSIDIAN_INBOX') or '',
    ORG = os.getenv('ORG') or '',
    PROJECTS = os.getenv('PROJECTS') or '',
    ARCHIVES = os.getenv('ARCHIVES') or '',

    ASSETS_DIR = os.getenv('ASSETS_DIR') or '',
    ASSETS = os.getenv('ASSETS') or '',
    ATTACHMENTS = os.getenv('ATTACHMENTS') or '',

    GREP_IGNORE = os.getenv('GREP_NOTES_IGNORE') or '',
  },
  org = {
    INBOX = os.getenv('ORG_INBOX') or '',
    MAIN = os.getenv('ORG_MAIN') or '',
    WORK = os.getenv('ORG_WORK') or '',
    REFERENCES = os.getenv('ORG_REFERENCES') or '',
    CALENDAR = os.getenv('ORG_CALENDAR') or '',
    PURCHASES = os.getenv('ORG_PURCHASES') or '/home/celso/notes/0 org/Purchases.org',
  },
}

-- table extend dirs
state.dirs = {
  work = {
    edge_server = os.getenv('EDGE_SERVER') or '',
    airflow_pipeline = os.getenv('AIRFLOW_PIPELINE') or '',
    io = '/home/celso/work/io',
  },
  format_with_eslint = {
    'ecommerce',
  },
  disable_eslint_lsp = {
    'integrations',
    'io',
    'notes',
    'dotfiles',
  },
  dont_format = {
    '.local/share/nvim/lazy', -- ~/.local/share/nvim/lazy
  },
}

state.icons = {
  lsp = '',    -- ',
  format = '', -- ' ',
  notes = ' ',
  clock = ' ',
  db = ' ',
  code = ' ',
  agent = '󱚞 ',
  term = ' ',
  git = {
    added = ' +',
    modified = ' ~',
    removed = ' -',
    branch = ' ',
    ahead = '',
    behind = '',
    git = ' ',
    commit = ' ',
    diff = ' ',
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
    vertical = ' | ',
  },
  dap = {
    breakpoint = '',
  },
}

state.notes_tabname = state.icons.notes .. 'notes'

state.cmd = {
  git = {
    commits_ahead_of_origin = 'git rev-list --count HEAD ^origin/$(git branch --show-current)',
    commits_behind_origin = 'git rev-list --count ^HEAD origin/$(git branch --show-current)',
  },
}

state.hl = {
  text = {
    text = '@text',
    highlight = 'Title',
    bold = 'Bold',
    subtext = '@comment',
    warn = 'WarningMsg',
  },
  highlight = 'MiniStatuslineModeOther',
  warn = 'LspDiagnosticsVirtualTextWarning',
}

state.ignore = {
  grep = {
    'pnpm-lock.yaml',
    'instascan.min.js',
  },
  explorer = {
    '*.org_archive',
  },
}

--- filsubtextetypes to close with q
state.close_with_q = {
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

--- check root file for specific stack
state.root = {
  vue = 'vite.config.ts',
}

state.statusline_show_filepath = true
state.statusline_show_position = false
state.statusline_show_time = false

-- Save swap file and trigger CursorHold
vim.opt.updatetime = 200
vim.opt.swapfile = false

vim.opt.tabstop = 4    -- Number of spaces tabs count for
vim.opt.shiftwidth = 4 -- Size of an indent - this seems to affect conform

vim.o.winborder = 'rounded'
vim.opt.spelllang = { 'en', 'pt' }
vim.opt.spellfile = vim.fn.expand('~/.config/nvim/spell/en.utf-8.add')

vim.o.spellcapcheck = ''
vim.opt.autowrite = true -- Enable autowrite

vim.opt.fillchars = {
  fold = ' ',
  foldopen = '▾',
  foldclose = '▸',
  foldinner = ' ',
  foldsep = ' ',
  eob = ' ', -- disable EOF tilde
}

-- only set clipboard if not in ssh, to make sure the OSC 52
-- integration works automatically.
vim.opt.clipboard = 'unnamedplus' -- Sync with system clipboard
vim.opt.completeopt = 'menu,menuone,noselect'
vim.opt.conceallevel = 2          -- Hide * markup for bold and italic, but not markers with substitutions
-- vim.opt.concealcursor = 'i' -- Conceal on cursor line in normal mode
vim.opt.confirm = true            -- Confirm to save changes before exiting modified buffer
vim.opt.cursorline = true         -- Enable highlighting of the current line
vim.opt.expandtab = true          -- Use spaces instead of tabs
vim.opt.foldlevel = 99
vim.opt.foldmethod = 'indent'
vim.opt.foldtext = ''
-- vim.opt.formatexpr = "v:lua.LazyVim.format.formatexpr()"
vim.opt.formatoptions = 'jcroqlnt' -- tcqj
vim.opt.grepformat = '%f:%l:%c:%m'
vim.opt.grepprg = 'rg --vimgrep'
vim.opt.ignorecase = true      -- Ignore case
vim.opt.inccommand = 'nosplit' -- preview incremental substitute
vim.opt.jumpoptions = 'view'
vim.opt.laststatus = 3         -- global statusline
vim.opt.linebreak = true       -- Wrap lines at convenient points
vim.opt.list = true            -- Show some invisible characters (tabs...
vim.opt.mouse = 'a'            -- Enable mouse mode
vim.opt.number = true          -- Print line number
vim.opt.pumblend = 10          -- Popup blend
vim.opt.pumheight = 10         -- Maximum number of entries in a popup
vim.opt.ruler = false          -- Disable the default ruler
vim.opt.scrolloff = 4          -- Lines of context
vim.opt.sessionoptions = { 'buffers', 'curdir', 'tabpages', 'winsize', 'help', 'globals', 'skiprtp', 'folds' }
vim.opt.shiftround = true      -- Round indent
vim.opt.shiftwidth = 2         -- Size of an indent
vim.opt.shortmess:append({
  W = true,
  I = false, -- disable intro screen
  c = true,
  C = true,
})
vim.opt.showmode = false   -- Dont show mode since we have a statusline
vim.opt.sidescrolloff = 8  -- Columns of context

vim.opt.signcolumn = 'yes' -- Always show the signcolumn, otherwise it would shift the text each time
vim.opt.smartcase = true   -- Don't ignore case with capitals
vim.opt.smartindent = true -- Insert indents automatically
vim.opt.smoothscroll = true
vim.opt.spelllang = { 'en' }
vim.opt.splitbelow = true                         -- Put new windows below current
vim.opt.splitkeep = 'screen'
vim.opt.splitright = true                         -- Put new windows right of current
vim.opt.termguicolors = true                      -- True color support
vim.opt.timeoutlen = vim.g.vscode and 1000 or 300 -- Lower than default (1000) to quickly trigger which-key
vim.opt.undofile = true
vim.opt.undolevels = 10000
vim.opt.updatetime = 200               -- Save swap file and trigger CursorHold
vim.opt.virtualedit = 'block'          -- Allow cursor to move where there is no text in visual block mode
vim.opt.wildmode = 'longest:full,full' -- Command-line completion mode
vim.opt.winminwidth = 5                -- Minimum window width
vim.opt.wrap = false                   -- Disable line wrap

state.web = {
  jira = state.env.work.jira or '',
}
