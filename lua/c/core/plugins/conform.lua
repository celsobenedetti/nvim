return {
  { -- Autoformat
    'stevearc/conform.nvim',
    opts = {
      notify_on_error = false,
      format_on_save = function()
        if not vim.g.autoformat then
          return
        end
        return {
          timeout_ms = 500,
          lsp_fallback = true,
          filter = function(client)
            return client.name ~= 'tsserver'
          end,
        }
      end,
      formatters_by_ft = {
        lua = { 'stylua' },
        python = { 'isort', 'black' },
        markdown = { { 'markdownlint-cli2' } },
        json = { { 'prettierd' } },
        toml = { { 'taplo' } },

        sh = { { 'shfmt' } },
        bash = { { 'shfmt' } },
        zsh = { { 'shfmt' } },

        javascript = { { 'prettierd' } },
        javascriptreact = { { 'prettierd' } },
        typescript = { { 'prettierd' } },
        typescriptreact = { { 'prettierd' } },
      },
      formatters = {
        goimports = {
          prepend_args = { '-local', 'github.com/celsobenedetti/' },
        },
      },
    },
  },
}
