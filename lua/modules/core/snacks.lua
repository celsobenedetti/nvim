return {

  "folke/snacks.nvim",
  keys = {
    {
      "<leader>no",
      function()
        Snacks.picker.notifications()
      end,
      desc = "Notification History",
    },
  },
}
