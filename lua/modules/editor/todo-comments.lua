return {
  "folke/todo-comments.nvim",
  opts = function(_, opts)
    opts.keywords = vim.tbl_deep_extend("force", opts.keywords or {}, {
      WIP = { icon = " ", color = "warning" },
    })
  end,
}
