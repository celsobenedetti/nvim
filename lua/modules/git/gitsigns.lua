return {
  {
    "lewis6991/gitsigns.nvim",
    keys = {
      {
        "<leader>gA",
        function()
          local gs = package.loaded.gitsigns
          gs.stage_buffer()
        end,
        desc = "gitsigns: stage buffer",
      },
      {
        "<leader>gR",
        function()
          local gs = package.loaded.gitsigns
          gs.reset_buffer()
        end,
        desc = "gitsigns: reset buffer",
      },
      {
        "<leader>gr",
        function()
          local gs = package.loaded.gitsigns
          gs.reset_hunk()
        end,
        desc = "gitsigns: reset hunk",
      },
      {
        "<leader>ga",
        function()
          local gs = package.loaded.gitsigns
          gs.stage_hunk()
        end,
        desc = "gitsigns: stage hunk",
      },
      { "[g", ":Gitsigns prev_hunk<CR>", desc = "Prev git diff hunk" },
      { "]g", ":Gitsigns next_hunk<CR>", desc = "Next git diff hunk" },

      map("n", "<leader>gid", function()
        local gs = package.loaded.gitsigns
        gs.toggle_word_diff()
        gs.toggle_linehl()
        gs.toggle_deleted()
      end, { desc = "Gitsigns: toggle inline diff" }),
    },
  },
}
