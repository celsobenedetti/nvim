local is_conflict_enabled = true

return {
  {
    'akinsho/git-conflict.nvim',
    version = '*',
    enabled = is_conflict_enabled,
    config = function()
      require('git-conflict').setup {
        default_mappings = false,
      }

      vim.keymap.set('n', '<leader>co', ':GitConflictChooseOurs<CR>')
      vim.keymap.set('n', '<leader>ct', ':GitConflictChooseTheirs<CR>')
      vim.keymap.set('n', '<leader>cb', ':GitConflictChooseBoth<CR>')
      vim.keymap.set('n', '<leader>c0', ':GitConflictChooseNone<CR>')
      vim.keymap.set('n', '[x', ':GitConflictrevConflict<CR>')
      vim.keymap.set('n', ']x', ':GitConflictNextConflict<CR>')
    end,
  },
}
