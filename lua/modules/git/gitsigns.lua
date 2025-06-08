return {
  { -- Adds git related signs to the gutter, as well as utilities for managing changes

    'lewis6991/gitsigns.nvim',
    opts = {
      signs = {
        add = { text = '│ ' },
        change = { text = '~' },
        delete = { text = '' },
        topdelete = { text = '‾' },
        changedelete = { text = '~' },
      },

      on_attach = function(buffer)
        local gs = package.loaded.gitsigns

        local function map(mode, l, r, desc)
          vim.keymap.set(mode, l, r, { buffer = buffer, desc = desc })
        end

        -- stylua: ignore start
        map("n", "]h", gs.next_hunk, "Gitsigns: Next Hunk")
        map("n", "[h", gs.prev_hunk, "Gitsigns: Prev Hunk")
        map("n", "<leader>gu", gs.undo_stage_hunk, "Gitsigns: Undo Stage Hunk")
        map({ "n", "v" }, "<leader>ga", ":Gitsigns stage_hunk<CR>", "Gitsigns: Stage Hunk")
        map("n", "<leader>gA", gs.stage_buffer, "Gitsigns: Stage Buffer")
        map({ "n", "v" }, "<leader>gr", ":Gitsigns reset_hunk<CR>", "Gitsigns: Reset Hunk")
        map("n", "<leader>gR", gs.reset_buffer, "Gitsigns: Reset Buffer")
        map("n", "<leader>gp", gs.preview_hunk_inline, "Gitsigns: Preview Hunk Inline")
        map("n", "<leader>gb", function() gs.blame_line({ full = true }) end, "Gitsigns: Blame Line")
        map("n", "<leader>gtw", function() gs.toggle_word_diff() end, "Gitsigns: toggle word diff")
        map("n", "<leader>gtl", function() gs.toggle_linehl() end, "Gitsigns: toggle line hl")
        map("n", "<leader>gtd", function() gs.toggle_deleted() end, "Gitsigns: toggle deleted")
        -- stylua: ignore end

        -- all together "toggle inline diff"
        map('n', '<leader>gid', function()
          gs.toggle_word_diff()
          gs.toggle_linehl()
          gs.toggle_deleted()
        end, 'Gitsigns: toggle inline diff')

        -- map("n", "<leader>gd", gs.diffthis, "Gitsigns: Diff This")
        -- map("n", "<leader>gD", function() gs.diffthis("~") end, "Gitsigns: Diff This ~")
        map({ 'o', 'x' }, 'ih', ':<C-U>Gitsigns select_hunk<CR>', 'Gitsigns: Select Hunk')
      end,
    },
  },
}
