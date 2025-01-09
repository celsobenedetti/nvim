return {
  'ThePrimeagen/harpoon',
  lazy = true,
  branch = 'harpoon2',
  opts = {
    menu = {
      save_on_toggle = true,
      width = vim.api.nvim_win_get_width(0) - 4,
    },
  },
  keys = {
    {
      '<leader>m',
      function()
        require('harpoon'):list():add()
      end,
      desc = 'Harpoon file',
    },
    {
      'mm',
      function()
        local harpoon = require 'harpoon'
        harpoon.ui:toggle_quick_menu(harpoon:list())
      end,
      desc = 'Harpoon quick menu',
    },
    {
      'ma',
      function()
        require('harpoon'):list():select(1)
      end,
      desc = 'Harpoon to file 1',
    },
    {
      'ms',
      function()
        require('harpoon'):list():select(2)
      end,
      desc = 'Harpoon to file 2',
    },
    {
      'md',
      function()
        require('harpoon'):list():select(3)
      end,
      desc = 'Harpoon to file 3',
    },
    {
      'mf',
      function()
        require('harpoon'):list():select(4)
      end,
      desc = 'Harpoon to file 4',
    },
    {
      'mg',
      function()
        require('harpoon'):list():select(5)
      end,
      desc = 'Harpoon to file 5',
    },
  },
}
