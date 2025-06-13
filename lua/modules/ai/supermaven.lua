return {
  -- {
  --   'supermaven-inc/supermaven-nvim',
  --   lazy = not C.opt.supermaven,
  --   config = function()
  --     require('supermaven-nvim').setup {
  --       keymaps = {
  --         accept_suggestion = '<C-a>',
  --         clear_suggestion = '<C-]>',
  --         accept_word = '<C-j>',
  --       },
  --       disable_inline_completion = false, -- disables inline completion for use with cmp
  --       disable_keymaps = false, -- disables built in keymaps for more manual control
  --       condition = function()
  --         return C.opt.supermaven
  --       end,
  --     }
  --   end,
  -- },

  {
    'supermaven-inc/supermaven-nvim',
    config = function()
      require('supermaven-nvim').setup {}
    end,
  },
}
