-- NOTE: 2025-07-22
-- disabling this since there are some inconsistencies with the layouts
-- for instance
--  zen mode does not work correctly
--  can't move windows, like help
-- { import = "lazyvim.plugins.extras.ui.edgy" },
return {
  "folke/edgy.nvim",
  enabled = false,
  opts = function(_, opts)
    opts.animate = vim.tbl_deep_extend("force", opts.animate or {}, {
      enabled = true,
      duration = 25,
      fps = 120, -- frames per second
      cps = 120, -- cells per second
      -- on_begin = function()
      --   vim.g.minianimate_disable = true
      -- end,
      -- on_end = function()
      --   vim.g.minianimate_disable = false
      -- end,
      -- -- Spinner for pinned views that are loading.
      -- -- if you have noice.nvim installed, you can use any spinner from it, like:
      -- -- spinner = require("noice.util.spinners").spinners.circleFull,
      -- spinner = {
      --   frames = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" },
      --   interval = 80,
      -- },
    })
  end,
}
