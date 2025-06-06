return {
  {
    'mfussenegger/nvim-lint',
    event = 'VeryLazy',
    config = function()
      require('lint').linters_by_ft = {
        bash = { 'shellcheck', 'bash' },
        sh = { 'shellcheck' },
        make = { 'checkmake' },
        terraform = { 'trivy' },
        typescript = { 'oxlint' },
        javascript = { 'oxlint' },
        -- go = { 'golangcilint' },
        -- TODO: should only run on .github path https://github.com/mfussenegger/nvim-lint/issues/685#issuecomment-2434755134
        -- yaml = { 'actionlint' },
        zsh = { 'zsh' },
      }
      -- Show linters for the current buffer's file type
      vim.api.nvim_create_user_command('LintInfo', function()
        local filetype = vim.bo.filetype
        local linters = require('lint').linters_by_ft[filetype]

        if linters then
          print('Linters for ' .. filetype .. ': ' .. table.concat(linters, ', '))
        else
          print('No linters configured for filetype: ' .. filetype)
        end
      end, {})

      vim.api.nvim_create_autocmd({ 'BufWritePost' }, {
        callback = function()
          require('lint').try_lint()
        end,
        group = vim.api.nvim_create_augroup('nvim-lint-bufwritepost', { clear = true }),
      })
    end,
  },
}
