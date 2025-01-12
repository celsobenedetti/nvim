-- TODO:  Supermaven feels better suited, but found lots of issues
return {
  {
    'zbirenbaum/copilot.lua',
    lazy = not C.opt.copilot,
    keys = {
      { '<leader>tc', require('core.config.toggles').copilot, { desc = 'Toggle copilot' } },
    },
    opts = {
      suggestion = { enabled = false },
      panel = { enabled = false },
    },

    dependencies = {
      {
        'zbirenbaum/copilot-cmp',
        lazy = not C.opt.copilot,
        config = function()
          require('copilot_cmp').setup()
        end,
      },
    },
  },
}
