return {
  'mason-org/mason.nvim',
  opts = {
    ensure_installed = {
      'shellcheck',
      'shfmt',
      'checkmake',
      'trivy',
      'ols',
      'vue-language-server',
    },
  },
}
