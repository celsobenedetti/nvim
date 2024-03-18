return {
  { -- Autoformat
    'stevearc/conform.nvim',
    opts = {
      notify_on_error = false,
      format_on_save = function()
        return {
          timeout_ms = 500,
          lsp_fallback = true,
          filter = function(client)
            return vim.g.autoformat and client.name ~= 'tsserver'
          end,
        }
      end,
      formatters_by_ft = {
        go = { 'goimports' },
        lua = { 'stylua' },
        python = { 'isort', 'black' },
        markdown = { { 'markdownlint-cli2' } },

        typescript = { { 'prettierd' } },
        javascript = { { 'prettierd' } },
        javascriptreact = { { 'prettierd' } },
        typescriptreact = { { 'prettierd' } },

        json = { { 'prettierd' } },
        toml = { { 'taplo' } },

        sh = { { 'shfmt' } },
        bash = { { 'shfmt' } },
        zsh = { { 'shfmt' } },
      },
      formatters = {
        goimports = {
          prepend_args = { '-local', 'github.com/celsobenedetti/' },
        },
      },
    },
  },
}
