return {
  {
    'mfussenegger/nvim-lint',
    event = 'VeryLazy',
    opts = function(_, opts)
      opts.linters_by_ft = vim.tbl_deep_extend('keep', opts.linters_by_ft or {}, {
        bash = { 'shellcheck', 'bash' },
        sh = { 'shellcheck' },
        make = { 'checkmake' },
        go = { 'golangcilint' },
        typescript = { 'oxlint' },
        javascript = { 'oxlint' },
        vue = { 'oxlint' },
        -- zsh = { "zsh" },
      })

      vim.api.nvim_create_user_command('LintInfo', function()
        local filetype = vim.bo.filetype
        local linters = require('lint').linters_by_ft[filetype]

        if linters then
          print('Linters for ' .. filetype .. ': ' .. table.concat(linters, ', '))
        else
          print('No linters configured for filetype: ' .. filetype)
        end
      end, {})
    end,
  },
}
