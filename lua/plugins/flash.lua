-- Flash enhances the built-in search functionality by showing labels
-- at the end of each match, letting you quickly jump to a specific
-- location.

return {
  {
    'folke/flash.nvim',
    -- event = 'VeryLazy',
    vscode = true,
    ---@type Flash.Config
    opts = {},
    keys = {
      {
        's',
        mode = { 'n', 'o' },
        function()
          state.insert_when_entering_terminal = false
          require('flash').jump()
          state.insert_when_entering_terminal = true
        end,
        desc = 'Flash',
      },
      -- stylua: ignore
      { "S", mode = { "n", "o", "x" }, function() require("flash").treesitter() end, desc = "Flash Treesitter" },
      {
        'r',
        mode = 'o',
        function()
          require('flash').remote()
        end,
        desc = 'Remote Flash',
      },
      {
        'R',
        mode = { 'o', 'x' },
        function()
          require('flash').treesitter_search()
        end,
        desc = 'Treesitter Search',
      },
      {
        '<c-s>',
        mode = { 'c' },
        function()
          require('flash').toggle()
        end,
        desc = 'Toggle Flash Search',
      },
      -- Simulate nvim-treesitter incremental selection
      {
        '<c-space>',
        mode = { 'n', 'o', 'x' },
        function()
          require('flash').treesitter({
            actions = {
              ['<c-space>'] = 'next',
              ['<BS>'] = 'prev',
            },
          })
        end,
        desc = 'Treesitter Incremental Selection',
      },
    },
  },
}
