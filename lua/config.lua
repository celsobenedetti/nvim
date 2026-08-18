--- Global source of truth for all read-only configuration.
---
---@class Config
local M = {
  supermaven = true,
  eslint_autoformat = true,
  statusline = true,
  colorcolumn = 80, -- column highlighted by the colorcolumn toggle (<leader>u|)

  icons = {
    lsp = '', -- ',
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
  },

  dirs = {
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
  },

  hl = {
    text = {
      text = '@text',
      highlight = 'Title',
      bold = 'Bold',
      subtext = '@comment',
      warn = 'WarningMsg',
    },
    highlight = 'MiniStatuslineModeOther',
    warn = 'LspDiagnosticsVirtualTextWarning',
  },

  cmd = {
    git = {
      commits_ahead_of_origin = 'git rev-list --count HEAD ^origin/$(git branch --show-current)',
      commits_behind_origin = 'git rev-list --count ^HEAD origin/$(git branch --show-current)',
    },
  },

  ignore = {
    grep = {
      'pnpm-lock.yaml',
      'instascan.min.js',
    },
    explorer = {
      '*.org_archive',
    },
  },

  --- filsubtextetypes to close with q
  close_with_q = {
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
  },

  --- check root file for specific stack
  root = {
    vue = 'vite.config.ts',
  },

  lazy_nvim_config = {
    performance = {
      rtp = {
        disabled_plugins = {
          'gzip',
          'matchit',
          'matchparen',
          'netrwPlugin',
          'tarPlugin',
          'tohtml',
          'tutor',
          'zipPlugin',
        },
      },
    },
  },

  env = {
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
  },
}

M.web = {
  jira = M.env.work.jira or '',
}

local treesitter = {
  --- filetypes to highlight with treesitter
  highlight = {
    'gitcommit',
    'go',
    'javascript',
    'json',
    'jsx',
    'lua',
    'markdown',
    'python',
    'sql',
    'tsx',
    'typescript',
    'vue',
    'yaml',
  },
}

treesitter.ensure_installed = vim.list_extend(vim.deepcopy(treesitter.highlight), {
  'bash',
  'c',
  'diff',
  'html',
  'jsdoc',
  'lua',
  'luadoc',
  'luap',
  'markdown_inline',
  'printf',
  'python',
  'query',
  'regex',
  'sql',
  'toml',
  'vim',
  'vimdoc',
  'xml',
})
M.treesitter = treesitter

local keys = {
  ['<C-S-g>'] = '<C-S-g>',
  ['<C-/>'] = '<C-/>',
  ['<C-S-N>'] = '<S-Down>',
  ['<C-tab>'] = '<C-tab>',
  ['<C-S-tab>'] = '<C-S-tab>',
}

if os.getenv('TMUX') then
  keys['<C-/>'] = '<C-_>'
end

if os.getenv('GHOSTTY_BIN_DIR') then
  keys['<C-S-N>'] = 'NOTES'
  keys['<C-tab>'] = 'TABNEXT'
  keys['<C-S-tab>'] = 'TABPREV'
  keys['<C-S-O>'] = '♠'
  keys['<C-S-E>'] = '♣'
end

M.keys = keys

return M
