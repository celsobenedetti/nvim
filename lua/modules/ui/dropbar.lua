return {
  {
    "Bekaboo/dropbar.nvim",
    event = "VeryLazy",
    config = function()
      local config = require("dropbar.configs")
      config.opts.icons.kinds.dir_icon = function()
        return "", "Comment"
      end
      -- vim.keymap.set('n', '[;', dropbar_api.goto_context_start, { desc = 'Go to start of current context' })
      -- vim.keymap.set('n', '];', dropbar_api.select_next_context, { desc = 'Select next context' })
    end,

    -- NOTE: 2025-07-22 this is not useful at all it seems
    -- keys = {
    --   {
    --     "<leader>;",
    --     function()
    --       require("dropbar.api").pick()
    --     end,
    --     desc = "Pick symbols in winbar",
    --   },
    -- },
  },
}
