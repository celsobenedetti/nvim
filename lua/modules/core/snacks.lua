return {

  "folke/snacks.nvim",
  -- stylua: ignore
  keys = {
    { "<leader>no", function() Snacks.picker.notifications() end, desc = "Notification History", },
    { "<leader>rg", function() Snacks.picker.grep() end, desc = "Grep", },
    { "<leader>dd", function() Snacks.bufdelete() end, desc = "delete buffer", },
    { "<leader>dot", function() Snacks.picker.files({cwd="~/.dotfiles", title = "~/.dotfiles", hidden = true, }) end, desc = "search dotfiles", },
    { "<leader>of", function() Snacks.picker.files({cwd="~/notes", title = " Org Files", ft ="org" }) end, desc = "search orgifles", },
    { "<leader>fn", function() Snacks.picker.files({cwd="~/notes", title = "All notes",  }) end, desc = "search all notes", },
  },
}
