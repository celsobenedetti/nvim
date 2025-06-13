-- TODO:  Supermaven feels better suited, but found lots of issues

if true then
  return {}
end
return {
  {
    'zbirenbaum/copilot.lua',
    lazy = not C.opt.copilot,
    keys = {
      { '<leader>tc', require('config.toggles').copilot, { desc = 'Toggle copilot' } },
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
