return {
  {
    'supermaven-inc/supermaven-nvim',
    opts = function(_, opts)
      opts.disable_inline_completion = not vim.g.supermaven_inline_completion
    end,

    keys = {
      { '<leader>tS', ':SupermavenToggle<CR>' },
    },
  },
}
