return {
  'mason-org/mason.nvim',
  opts = {
    ensure_installed = {
      'shellcheck',
      'shfmt',
      'checkmake',
      'trivy',
      'oxlint',
      'ols',
    },
  },
}
