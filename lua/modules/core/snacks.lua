return {

  "folke/snacks.nvim",
  -- stylua: ignore
  keys = {
    { "<leader>no", function() Snacks.picker.notifications() end, desc = "Notification History", },
    { "<leader>rg", function() Snacks.picker.grep() end, desc = "Grep", },
  },
}
