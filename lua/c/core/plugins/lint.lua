return {
  {
    'mfussenegger/nvim-lint',
    event = 'VeryLazy',
    config = function()
      local is_deno = require('lspconfig.util').root_pattern('deno.json', 'deno.jsonc')
      local js_linter = is_deno and 'deno' or 'prettierd'

      require('lint').linters_by_ft = {
        bash = { 'shellcheck' },
        sh = { 'shellcheck' },
        make = { 'checkmake' },
        typescript = { js_linter },
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
