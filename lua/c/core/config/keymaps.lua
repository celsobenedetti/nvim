map('n', '<leader>la', '<cmd>Lazy<cr>', { desc = 'Lazy UI' })
map('n', '<leader>ma', '<cmd>Mason<cr>', { desc = 'Mason UI' })

-- new file
map('n', '<leader>fn', ':enew<cr>', { desc = 'New File' })
map('n', '<leader>re', ':e! %<cr>', { desc = 'Refresh Buffer' })
map('n', '<leader>dd', ':bdelete<cr>', { desc = 'Delete Buffer' })
map('n', '<leader>cd', ':colorscheme default<cr>', { desc = 'Set default colorscheme' })

map('n', '[g', ':Gitsigns prev_hunk<CR>', { desc = 'Prev git diff hunk' })
map('n', ']g', ':Gitsigns next_hunk<CR>', { desc = 'Next git diff hunk' })

-- macro
map('v', '<leader>Q', ':norm @q<CR>', { desc = 'Execute @q macro in selected lines' })

map('x', 'p', '"_dP', { desc = 'Paste without losing register' }) --hold on to register when pasting and replace text

-- Commands
map('n', '<leader>C', ':Clip<CR>', { desc = 'Copy file path to clipboard' })
map('n', '<leader>n', ':Note<CR>', { desc = 'Run bash on current line' })

map('n', '<leader>B', function()
  vim.api.nvim_feedkeys(Keys 'V!bash<CR>', 'n', true)
end, { desc = 'Run bash on current line' })

map('v', '<leader>B', function()
  vim.api.nvim_feedkeys(Keys '!bash<CR>', 'n', true)
end, { desc = 'Run bash on current line' })

map('n', '<leader>rm', function()
  vim.api.nvim_feedkeys(Keys ':!rm %<CR>', 'n', true)
  vim.api.nvim_feedkeys(Keys ':bdelete<cr>', 'n', true)
end, { desc = 'rm buffer file' })

local track_position_before_relative_jump = require 'c.functions.relative_jump'
map('n', 'k', track_position_before_relative_jump.up)
map('n', 'j', track_position_before_relative_jump.down)

map('n', 'gv', function()
  vim.api.nvim_feedkeys(Keys '<c-w>v', 'n', true)
  require('telescope.builtin').lsp_definitions { reuse_win = true }
end, { desc = 'Split vertical and go to definition' })

local surround_map = require('c.functions.surround').surround_map
surround_map({ '(', ')' }, '(')
surround_map({ '[', ']' }, '[')
surround_map({ '"' }, '"')
surround_map({ "'" }, "'")
surround_map({ '`' }, '`')
surround_map({ '<leader>b' }, '**')
surround_map({ 'i', '<leader>i' }, '_')
surround_map({ '<leader>~' }, '~~')
