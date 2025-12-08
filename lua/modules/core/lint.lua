return {
  {
    'mfussenegger/nvim-lint',
    event = 'VeryLazy',
    config = function(_)



require('lint').linters_by_ft = {

        bash = { 'shellcheck', 'bash' },
        sh = { 'shellcheck' },
        make = { 'checkmake' },
        go = { 'golangcilint' },
        typescript = { 'oxlint', 'eslint' },
        javascript = { 'oxlint', 'eslint' },
        vue = { 'oxlint', 'eslint' },
        -- zsh = { "zsh" },
}

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
