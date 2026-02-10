local tmux = require('lib.tmux')

map('n', 'ga', function()
  local cmd = string.format('git add -p %s', vim.fn.expand('%'))
  tmux.neww(cmd)
end, {
  desc = 'tmux: neww `add.sh %`',
})
map('n', 'gC', function()
  tmux.neww('commit.sh')
end, {
  desc = 'tmux: neww `commit.sh`',
})
