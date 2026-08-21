return {
  {
    'lewis6991/gitsigns.nvim',
    event = 'VeryLazy',
    config = function()
      require('gitsigns').setup({
        diff_opts = {
          -- Pin: `word_diff` (intra-line highlights) requires the internal
          -- diff. Without this it silently no-ops if `diffopt` drops
          -- `internal` (e.g. when a colorscheme or plugin sets it).
          internal = true,
          -- Stack `:Gitsigns diffthis` vertically instead of side-by-side.
          -- This only affects diffthis, not inline/word diffs.
          vertical = false,
        },
        -- Where the diff buffer goes: 'aboveleft' (default) puts it above the
        -- working file, 'belowright' below it.
        diffthis = {
          split = 'aboveleft',
        },
      })

      vim.cmd.cnoreabbrev('gitsigns Gitsigns')
    end,
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
        'gid',
        function()
          local gs = package.loaded.gitsigns
          -- Master toggle: read the current state from one flag and set all
          -- layers to the same value, so they can't drift into mixed states
          -- (the old triple-invert could). Deleted lines come back as
          -- persistent virtual lines (GitSignsDeleteVirtLn, delta minus
          -- style) — `show_deleted`/`toggle_deleted` are deprecated upstream
          -- but intentionally kept: per-hunk preview_hunk_inline() (see
          -- <leader>gip) can't show the whole-buffer removed view.
          local on = not require('gitsigns.config').config.word_diff
          gs.toggle_word_diff(on)
          gs.toggle_linehl(on)
          gs.toggle_deleted(on)
        end,
        desc = 'Gitsigns: toggle inline diff (word + line + deleted lines)',
      },
      {
        'gh',
        function()
          -- Per-hunk transient preview (preview_hunk_inline): removed lines
          -- as virtual lines with line numbers. Complementary to gid's
          -- persistent show_deleted view — this one tracks the cursor and
          -- clears on move.
          package.loaded.gitsigns.preview_hunk_inline()
        end,
        desc = 'Gitsigns: preview hunk inline (deleted lines)',
      },
      {
        '<leader>giR',
        function()
          local gs = package.loaded.gitsigns
          if state.git_diff_revision then
            -- Already diffing against a revision: back to the index
            gs.reset_base(true)
            gs.toggle_word_diff(false)
            gs.toggle_linehl(false)
            gs.toggle_deleted(false)
            state.git_diff_revision = nil
            vim.cmd('redrawstatus')
            return
          end
          local rev = vim.trim(vim.fn.input('Gitsigns: diff against revision: ', 'HEAD~1'))
          if rev == '' then
            return
          end
          gs.change_base(rev, true, function(err)
            if err then
              return
            end
            gs.toggle_word_diff(true)
            gs.toggle_linehl(true)
            gs.toggle_deleted(true)
            state.git_diff_revision = rev
            vim.cmd('redrawstatus')
          end)
        end,
        desc = 'Gitsigns: toggle global inline diff against revision',
      },
    },
  },
}
