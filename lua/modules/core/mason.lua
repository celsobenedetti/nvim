return {
  'mason-org/mason.nvim',
  lazy = false,
  keys = { { '<leader>ma', ':Mason<CR>', { desc = 'Mason' } } },
  cmd = 'Mason',
  opts = {
    ensure_installed = {
      'scheckmake',
      'eslint-lsp',
      'json-lsp',
      'ols',
      'shellcheck',
      'shfmt',
      'trivy',
      'vue-language-server',
    },
  },
}
