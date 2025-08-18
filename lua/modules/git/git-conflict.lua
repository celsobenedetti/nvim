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
      vim.keymap.set(
        'n',
        '<leader>co',
        ':GitConflictChooseOurs<CR>',
        { desc = 'git conflict: Choose the current branch changes' }
      )
      vim.keymap.set(
        'n',
        '<leader>ct',
        ':GitConflictChooseTheirs<CR>',
        { desc = 'git conflict: Choose the incoming branch changes' }
      )
      vim.keymap.set('n', '<leader>cb', ':GitConflictChooseBoth<CR>', { desc = 'git conflict: Choose both changes' })
      vim.keymap.set('n', '<leader>c0', ':GitConflictChooseNone<CR>', { desc = 'git conflict: Reject both changes' })
      vim.keymap.set('n', '[x', ':GitConflictrevConflict<CR>', { desc = 'git conflict: Go to the previous conflict' })
      vim.keymap.set('n', ']x', ':GitConflictNextConflict<CR>', { desc = 'git conflict: Go to the next conflict' })
    end,
  },
}
