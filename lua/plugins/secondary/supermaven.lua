local state = require('state')

return {
  {

    'supermaven-inc/supermaven-nvim',
    event = 'InsertEnter',
    enabled = state.supermaven,
    cmd = { 'SupermavenUseFree', 'SupermavenToggle' },
    opts = {
      keymaps = {
        accept_suggestion = nil, -- handled by blink.cmp
      },
      disable_inline_completion = false,
      ignore_filetypes = { 'bigfile', 'snacks_input', 'snacks_notif' },
    },
  },
}
