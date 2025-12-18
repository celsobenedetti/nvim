return {
  work = {
    edge_server = vim.g.env.WORK .. '/integrations-private',
  },
  dont_format = {
    '.local/share/nvim/lazy', -- ~/.local/share/nvim/lazy
  },
  format_with_eslint = {
    'ecommerce',
  },
  disable_eslint_lsp = {
    'integrations',
  },
}
