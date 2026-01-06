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
          'js-debug-adapter',
          'json-lsp',
          'lua-language-server',
          'ols',
          'oxlint',
          'prettier',
          'shellcheck',
          'shfmt',
          'stylua',
          'typescript-language-server',
          'vtsls',
          'vue-language-server',
        },
        auto_update = false,
        run_on_start = true,
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
