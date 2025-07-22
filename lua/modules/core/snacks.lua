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
    { "<leader>sr", function() require("persistence").load() end, desc = "Restore Session" },
    { "<leader>rs", function() require("persistence").load() end, desc = "Restore Session" },
    { "<leader>qS", function() require("persistence").select() end,desc = "Select Session" },
    { "<leader>ql", function() require("persistence").load({ last = true }) end, desc = "Restore Last Session" },
    { "<leader>qd", function() require("persistence").stop() end, desc = "Don't Save Current Session" },
    { "<leader>fF", function() Snacks.picker.git_files() end, desc = "Find Files (git-files)" },
  },

  config = function()
    Snacks.toggle.dim():map("<leader>tw")
  end,
}
