return {
  -- {
  --   'hedyhli/outline.nvim',
  --   keys = {
  --     { '<leader>out', ':Outline<CR>', desc = 'Toggle Outline' },
  --   },
  --   config = function()
  --     require('outline').setup({})
  --   end,
  -- },
  {
    'stevearc/aerial.nvim',
    opts = {
      layout = {
        default_direction = 'prefer_right',
      },
    },
    keys = {
      { '<leader>out', ':AerialToggle<CR>', desc = 'Toggle Outline' },
    },
    -- dependencies = {
    --   'nvim-treesitter/nvim-treesitter',
    --   'nvim-tree/nvim-web-devicons',
    -- },
  },
}
