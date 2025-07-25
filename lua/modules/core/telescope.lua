if true then
  -- NOTE: 2025-07-25
  -- I don't think I need this because snacks.picker has bufdelete actions
  return {}
end

return {
  "telescope/telescope.nvim",
  keys = {
    {
      "<leader>s<space>",
      function()
        require("telescope.builtin").buffers({
          layout_config = {
            prompt_position = "top",
          },
          sorting_strategy = "ascending",
        })
      end,
      desc = "Telescope: buffers",
    },
  },
  opts = function(_, opts)
    -- table extend way
    opts.pickers = vim.tbl_deep_extend("force", opts.pickers or {}, {
      buffers = {
        mappings = {
          i = {
            ["<C-d>"] = require("telescope.actions").delete_buffer,
          },
        },
      },
    })
  end,
}
