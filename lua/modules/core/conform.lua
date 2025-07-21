return {
  "conform.nvim",
  opts = function(_, opts)
    opts.formatters_by_ft = opts.formatters_by_ft or {}
    opts.formatters_by_ft.markdown = { "mfmt" }

    opts.formatters = vim.tbl_deep_extend("force", opts.formatters or {}, {
      goimports = {
        prepend_args = { "-local", "github.com/celsobenedetti/" },
      },
      mfmt = { command = "mfmt" },
      mfmt_org = { command = "mfmt", prepend_args = { "--parser=orgmode" } },
    })
  end,
}
