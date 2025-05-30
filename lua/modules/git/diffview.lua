local is_diffview_open = false

return {
  {
    'sindrets/diffview.nvim',
    event = 'VeryLazy',
    keys = {
      {
        '<leader>D',
        function()
          if is_diffview_open then
            is_diffview_open = false
            require('diffview').close()
          else
            is_diffview_open = true
            require('diffview').open()
          end
        end,
        desc = 'Toggle Diffview',
      },

      {
        '<leader>dhh',
        ':DiffviewFileHistory<CR>',
        desc = 'diffview: toggle file history',
      },
      {
        '<leader>dfh',
        ':DiffviewFileHistory --follow %<CR>',
        desc = 'diffview: current file history',
      },
    },
  },
}
