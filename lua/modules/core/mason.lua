return {
  {
    'mason-org/mason.nvim',
    lazy = false,
    keys = { { '<leader>ma', ':Mason<CR>', { desc = 'Mason' } } },
    cmd = 'Mason',
    config = true,
  },
  {
    'WhoIsSethDaniel/mason-tool-installer.nvim',
    cmd = 'MasonToolsUpdate',
    lazy = true,
    config = function()
      require('mason-tool-installer').setup({
        ensure_installed = {
          'bash-language-server',
          'eslint-lsp',
          'gopls',
          'json-lsp',
          'lua-language-server',
          'ols',
          'oxlint',
          'shellcheck',
          'shfmt',
          'stylua',
          'typescript-language-server',
          'vue-language-server',
        },
        auto_update = false,
        run_on_start = false,
        start_delay = 3000, -- 3 second delay
        debounce_hours = 5, -- at least 5 hours between attempts to install/update
        integrations = {
          ['mason-lspconfig'] = false,
          ['mason-null-ls'] = false,
          ['mason-nvim-dap'] = false,
        },
      })
    end,
  },
}
