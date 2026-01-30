return {
  'folke/todo-comments.nvim',
  keys = {
    -- stylua: ignore start
    { '<leader>tt', ':TodoQuickFix<CR>', desc = 'Todo/Fix/Fixme (Trouble)' },
    { ']t', function() require('todo-comments').jump_next() end, desc = 'Next Todo Comment', },
    { '[t', function() require('todo-comments').jump_prev() end, desc = 'Previous Todo Comment', },
    { '<leader>xt', '<cmd>Trouble todo toggle<cr>', desc = 'Todo (Trouble)' },
    { '<leader>xT', '<cmd>Trouble todo toggle filter = {tag = {TODO,FIX,FIXME}}<cr>', desc = 'Todo/Fix/Fixme (Trouble)' },
    { '<leader>st', function () Snacks.picker.todo_comments() end, desc = 'Todo/Fix/Fixme (Trouble)' },
    -- stylua: ignore end
  },
  opts = {
    keywords = {
      WIP = { icon = ' ', color = 'warning' },
      NOTE = { icon = '󰂺 ', color = vim.g.colors.lightgray },
      TODO = { icon = ' ', color = vim.g.colors.lightgray },
    },
  },
}
