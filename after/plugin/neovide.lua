if not vim.g.neovide then
  return
end

local cwd = require('lib.cwd')

map('n', '<C-S-E>', function()
  Snacks.explorer.open({ exclude = vim.g.ignore.explorer, ignored = true })
end, { desc = 'Snacks: explorer' })
map('n', '<C-S-O>', function()
  Snacks.picker.lsp_symbols({})
end, { desc = 'LSP Symbols' })
map('n', '<C-/>', function()
  Snacks.terminal(nil, { cwd = cwd.root() })
end, { desc = 'Terminal (Root Dir)', mode = { 'n', 't' } })
