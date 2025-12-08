return {
  'folke/todo-comments.nvim',
  opts = function(_, opts)
    opts.keywords = vim.tbl_deep_extend('force', opts.keywords or {}, {
      WIP = { icon = ' ', color = 'warning' },
      NOTE = { icon = '󰂺 ', color = vim.g.colors.lightgray },
      TODO = { icon = ' ', color = vim.g.colors.lightgray },
    })
  end,
}
