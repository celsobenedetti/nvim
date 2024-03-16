return {
  {
    'mfussenegger/nvim-lint',
    event = 'VeryLazy',
    config = function()
      require('lint').linters_by_ft = {
        bash = { 'shellcheck' },
        sh = { 'shellcheck' },
      }

      vim.api.nvim_create_autocmd({ 'BufWritePost' }, {
        callback = function()
          require('lint').try_lint()
        end,
        group = vim.api.nvim_create_augroup('nvim-lint-bufwritepost', { clear = true }),
      })
    end,
  },
}
