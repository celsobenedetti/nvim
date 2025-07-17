return {

  { -- Autoformat
    'stevearc/conform.nvim',
    config = function()
      local js_formatter = C.cwd.is_deno() and 'deno' or 'prettierd'
      require('conform').setup {
        log_level = vim.log.levels.WARN,
        notify_on_error = false,
        format_on_save = function()
          if not C.opt.autoformat then
            return
          end
          return { timeout_ms = 500, lsp_format = 'fallback' }
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
          markdown = { 'mfmt' },
          python = { 'isort', 'black' },
          sh = { 'shfmt' },
          sql = { 'sqlfluff' },
          -- BUG: this is cooked for now. 2025-07-14
          -- org = { 'mfmt_org' },
          toml = { 'taplo' },
          typescript = { js_formatter },
          typescriptreact = { js_formatter },
          yaml = { 'prettierd' },
          zsh = { 'shfmt' },
        },
        formatters = {
          goimports = {
            prepend_args = { '-local', 'github.com/celsobenedetti/' },
          },
          mfmt = { command = 'mfmt' },
          mfmt_org = { command = 'mfmt', prepend_args = { '--parser=orgmode' } },
        },
      }
    end,
  },
}
