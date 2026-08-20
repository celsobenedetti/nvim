return {
  {
    'lewis6991/gitsigns.nvim',
    event = 'VeryLazy',
    keys = {

      {
        'gb',
        function()
          local gs = package.loaded.gitsigns
          gs.blame_line()
        end,
        desc = 'gitsigns: blame line',
      },
      {
        '<leader>gA',
        function()
          local gs = package.loaded.gitsigns
          gs.stage_buffer()
        end,
        desc = 'gitsigns: stage buffer',
      },
      {
        '<leader>gR',
        function()
          local gs = package.loaded.gitsigns
          gs.reset_buffer()
        end,
        desc = 'gitsigns: reset buffer',
      },
      {
        '<leader>gr',
        function()
          local gs = package.loaded.gitsigns
          gs.reset_hunk()
        end,
        desc = 'gitsigns: reset hunk',
      },
      {
        '<leader>ga',
        function()
          local gs = package.loaded.gitsigns
          gs.stage_hunk()
        end,
        desc = 'gitsigns: stage hunk',
      },
      { '[g', ':Gitsigns prev_hunk<CR>', desc = 'Prev git diff hunk' },
      { ']g', ':Gitsigns next_hunk<CR>', desc = 'Next git diff hunk' },

      {
        '<leader>gid',
        function()
          local gs = package.loaded.gitsigns
          gs.toggle_word_diff()
          gs.toggle_linehl()
          gs.toggle_deleted()
        end,
        desc = 'Gitsigns: toggle inline diff',
      },
      {
        '<leader>giR',
        function()
          local gs = package.loaded.gitsigns
          local cache = require('gitsigns.cache').cache
          local buf = vim.api.nvim_get_current_buf()
          local cur = cache[buf] and cache[buf].git_obj and cache[buf].git_obj.revision
          if cur then
            -- Already diffing against a revision: back to the index
            gs.reset_base()
            gs.toggle_word_diff(false)
            gs.toggle_linehl(false)
            gs.toggle_deleted(false)
            return
          end
          local rev = vim.fn.input('Gitsigns: diff against revision: ', 'HEAD~1')
          if rev == '' then
            return
          end
          gs.change_base(vim.trim(rev))
          gs.toggle_word_diff(true)
          gs.toggle_linehl(true)
          gs.toggle_deleted(true)
        end,
        desc = 'Gitsigns: toggle inline diff against revision',
      },
    },
  },
}
