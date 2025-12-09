return {
  {
    'supermaven-inc/supermaven-nvim',
    event = 'InsertEnter',
    cmd = {
      'SupermavenUseFree',
      'SupermavenUsePro',
    },
    opts = {
      keymaps = {
        accept_suggestion = nil, -- handled by  blink.cmp
      },
      disable_inline_completion = not vim.g.supermaven,
      ignore_filetypes = { 'bigfile', 'snacks_input', 'snacks_notif' },
    },

    keys = {
      { '<leader>tS', ':SupermavenToggle<CR>' },
    },
  },
}
