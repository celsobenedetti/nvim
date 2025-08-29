local cwd = require 'lib.cwd'

return {
  'stevearc/conform.nvim',
  enabled = function()
    -- avoid formatting files in lazy.nvim managed repos
    return not cwd.is_path { 'lazy' }
  end,
  opts = function(_, opts)
    opts.formatters_by_ft = vim.tbl_deep_extend('force', opts.formatters_by_ft or {}, {
      markdown = { 'mfmt' },
      org = { 'mfmt_org' },
      gitcommit = { 'mfmt' },

      javascript = { 'prettierd' },
      typescript = { 'prettierd' },
      odin = { 'odinfmt' },
    })

    opts.formatters = vim.tbl_deep_extend('force', opts.formatters or {}, {
      goimports = { prepend_args = { '-local', 'github.com/celsobenedetti/' } },
      shfmt = { prepend_args = { '--indent', '4' } },
      mfmt = { command = 'mfmt' },
      mfmt_org = { command = 'mfmt', prepend_args = { '--parser=orgmode' } },
    })
  end,
}
