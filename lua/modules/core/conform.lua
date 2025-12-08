local cwd = require 'lib.cwd'
local eslint_projects = { 'ecommerce' }

return {
  'stevearc/conform.nvim',
  enabled = function()
    -- avoid formatting files in lazy.nvim managed repos
    return not cwd.matches { 'lazy' }
  end,
  opts = function(_, opts)
    local use_eslint = false
    for _, project in ipairs(eslint_projects) do
      if cwd.matches { project } then
        use_eslint = true
        break
      end
    end
    local fmt_js = use_eslint and { lsp_format = 'last', async = true } or { 'prettier' }

    opts.formatters_by_ft = vim.tbl_deep_extend('force', opts.formatters_by_ft or {}, {
      -- markdown = { 'mfmt' },
      -- org = { 'mfmt_org' },
      -- gitcommit = { 'mfmt' },
      --

      css = fmt_js,
      json = fmt_js,
      javascript = fmt_js,
      typescript = fmt_js,
      typescriptreact = fmt_js,
      vue = fmt_js,

      odin = { 'odinfmt' },
    })

    opts.formatters = vim.tbl_deep_extend('force', opts.formatters or {}, {
      goimports = { prepend_args = { '-local', 'github.com/celsobenedetti/' } },
      shfmt = { prepend_args = { '--indent', '4' } },
      -- mfmt = { command = 'mfmt' },
      -- mfmt_org = { command = 'mfmt', prepend_args = { '--parser=orgmode' } },
      prettierd = {
        env = {
          PRETTIERD_LOCAL_PRETTIER_ONLY = 'true',
        },
      },
    })
  end,
}
