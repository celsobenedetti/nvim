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
    agent = '󰚩 ',
    term = ' ',
    cmd = '$ ',
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
      revision = '󰐁',
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

  obsidian = {
    inbox = os.getenv('OBSIDIAN_INBOX') or '',
  },

  dirs = {
    notes = os.getenv('NOTES') or '',
    garden = os.getenv('GARDEN') or '',
    work_notes = os.getenv('WORK_NOTES') or '',
    org = os.getenv('ORG') or '',
    work = {
      edge_server = os.getenv('EDGE_SERVER') or '',
      airflow_pipeline = os.getenv('AIRFLOW_PIPELINE') or '',
      io = os.getenv('IO_DIR') or '',
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
      search = 'Search',
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
    fd = {
      ignore = [[
      --no-ignore
      --exclude .git
      --exclude node_modules
      --exclude public
      --exclude .vault
      --exclude .airflow
      --exclude .venv
      --exclude .fallow
      --exclude dist
      --exclude build
      ]],
    },
    rg = {
      -- these are only args for the rg command
      ignore = {
        '--no-heading',
        '--no-ignore',
        '--line-number',
        '--max-filesize',
        '1M',
        '-g',
        '!.git*',
        '-g',
        '!*.min.js',
        '-g',
        '!pnpm-lock.yaml',
        '-g',
        '!frontend/public*',
        '-g',
        '!frontend/vantine*',
        '-g',
        '!*.scss',
        '-g',
        '!*.css',
        '-g',
        '!*.html',
        '-g',
        '!*.txt',
        '-g',
        '!*.key',
        '-g',
        '!*static*',
        '-g',
        '!*build*',
        '-g',
        '!*drupal*',
        '-g',
        '!*quartz*',
      },
      -- org-mode archive-path property lines pollute results; dropped via
      -- rg -v in the fzf keymap and via quickfix filtering in :Grep (a bare
      -- positional pattern there would clash with :grep's appended -e pattern,
      -- which turns all other positionals into paths).
      exclude_lines = {
        'ARCHIVE_OLPATH',
      },
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

  filetypes = {
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
      'fugitive',
      'git',
    },
    -- `git` (fugitive patch buffers) is deliberately absent: its `gf` opens
    -- the file in the first tab instead, at the patch's own line, see
    -- after/ftplugin/git.lua.
    gf_open_in_top_split = {
      'terminal',
      'cmd-output',
    },
  },

  --- check root file for specific stack
  root = {
    vue = 'vite.config.ts',
  },

  lazy = {
    -- disabled: polls every file under lua/plugins/** every 2s and, on change,
    -- synchronously reloads all plugin specs on the main loop. Editing any
    -- plugin config file while a terminal-backed UI (fzf-lua, etc.) is open
    -- stalls the event loop mid-redraw and corrupts its screen buffer.
    change_detection = { enabled = false },
    defaults = {
      lazy = false,
      version = false, -- always use the latest git commit
    },
    checker = {
      enabled = true, -- check for plugin updates periodically
      notify = false, -- notify on update
    },
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

  org = {
    inbox = os.getenv('ORG_INBOX') or '',
    work = os.getenv('ORG_WORK') or '',
    references = os.getenv('ORG_REFERENCES') or '',
  },
  env = {
    WORK_JIRA = os.getenv('WORK_JIRA') or '',
    GREP_IGNORE = os.getenv('GREP_NOTES_IGNORE') or '',
    org = {},
  },
}

M.tabs = {
  notes = M.icons.notes .. 'notes',
}

M.web = {
  jira = M.env.WORK_JIRA or '',
}

local treesitter = {
  --- filetypes to highlight with treesitter
  highlight = {
    'css',
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

-- https://github.com/gennaro-tedesco/dotfiles/blob/28be096a90a7c1fbadde62bdac3fd2a78492fcde/nvim/lua/filetype.lua#L7
vim.filetype.add({
  filename = {
    ['.env'] = 'config',
  },
  pattern = {
    ['gitconf.*'] = 'gitconfig',
  },
})

return M
