return {
  {
    'MagicDuck/grug-far.nvim',
    -- Note (lazy loading): grug-far.lua defers all it's requires so it's lazy by default
    -- additional lazy config to defer loading is not really needed...
    config = function()
      -- optional setup call to override plugin options
      -- alternatively you can set options with vim.g.grug_far = { ... }
      require('grug-far').setup {
        -- options, see Configuration section below
        -- there are no required options atm
      }
    end,
    keys = {
      { '<leader>sed', '<cmd>GrugFar<cr>', desc = 'Sed' },
    },
  },

  -- search/replace in multiple files
  -- WIP: 2025-07-11 trying out grug-far insted, might replace this one
  -- {
  --   lazy = true,
  --   'nvim-pack/nvim-spectre',
  --   build = false,
  --   cmd = 'Spectre',
  --   opts = { open_cmd = 'noswapfile vnew' },
  --   -- stylua: ignore
  --   keys = {
  --     { "<leader>sed", function() require("spectre").open() end, desc = "Replace in files (Spectre)" },
  --   },
  -- },
}
