local state = require('state')

if os.getenv('PERF') == 'true' then
  state.performance = true
end

---@diagnostic disable-next-line: lowercase-global
map = vim.keymap.set

vim.api.nvim_create_user_command('RenameTab', function(opts)
  require('lib.tab').rename(opts.args)
end, { nargs = '?' })

state.lazy_nvim_config = {
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
}

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

state.keys = keys
