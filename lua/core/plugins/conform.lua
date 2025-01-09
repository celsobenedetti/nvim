return {

  { -- Autoformat
    'stevearc/conform.nvim',
    opts = function()
      local js_formatter = C.CWD.is_deno() and 'deno' or 'prettierd'

      return {
        log_level = vim.log.levels.WARN,
        notify_on_error = false,
        format_on_save = function()
          return {
            timeout_ms = 5000,
            lsp_fallback = true,
            filter = function(client)
              return C.opt.autoformat and client.name ~= 'tsserver'
            end,
          }
        end,
        formatters_by_ft = {
          bash = { 'shfmt' },
          go = { 'gofumpt', 'goimports' },
          graphql = { 'prettierd' },
          html = { 'prettierd' },
          css = { 'prettierd' },
          javascript = { js_formatter },
          javascriptreact = { js_formatter },
          json = { js_formatter },
          lua = { 'stylua' },
          markdown = { 'markdownlint-cli2' },
          python = { 'isort', 'black' },
          sh = { 'shfmt' },
          toml = { 'taplo' },
          typescript = { js_formatter },
          typescriptreact = { js_formatter },
          zsh = { 'shfmt' },
        },
        formatters = {
          goimports = {
            prepend_args = { '-local', 'github.com/celsobenedetti/' },
          },
        },
      }
    end,
  },
}
