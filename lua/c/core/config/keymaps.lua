map('n', '<leader>la', '<cmd>Lazy<cr>', { desc = 'Lazy UI' })

map('n', '<leader>ma', '<cmd>Mason<cr>', { desc = 'Mason UI' })

-- new file
map('n', '<leader>fn', ':enew<cr>', { desc = 'New File' })
map('n', '<leader>re', ':e! %<cr>', { desc = 'Refresh Buffer' })
map('n', '<leader>dd', ':Bdelete<cr>', { desc = 'Delete Buffer' })
map('n', '<leader><tab>', ':tabnext<cr>', { desc = 'Next Tab' })
map('n', 'ZQ', ':qa!<CR>', { desc = 'Quit all' })

map('n', '<leader>u1', ':colorscheme ' .. vim.g.colorscheme_1 .. '<CR>', { desc = 'Set colorscheme 1' })
map('n', '<leader>u2', ':colorscheme ' .. vim.g.colorscheme_2 .. '<CR>', { desc = 'Set colorscheme 2' })
map('n', '<leader>u3', ':colorscheme ' .. vim.g.colorscheme_3 .. '<CR>', { desc = 'Set colorscheme 3' })
map('n', '<leader>u4', ':colorscheme ' .. vim.g.colorscheme_4 .. '<CR>', { desc = 'Set colorscheme 4' })

map('n', '[g', ':Gitsigns prev_hunk<CR>', { desc = 'Prev git diff hunk' })
map('n', ']g', ':Gitsigns next_hunk<CR>', { desc = 'Next git diff hunk' })

-- macro
map('v', '<leader>Q', ':norm @q<CR>', { desc = 'Execute @q macro in selected lines' })

map('x', 'p', '"_dP', { desc = 'Paste without losing register' }) --hold on to register when pasting and replace text

-- Commands
map('n', '<leader>C', ':Clip<CR>', { desc = 'Copy file path to clipboard' })
map('n', '<leader>N', ':Note<CR>', { desc = 'Run bash on current line' })

map('n', '<leader>B', function()
  vim.api.nvim_feedkeys(Keys 'V!bash<CR>', 'n', true)
end, { desc = 'Run current line as bash command' })

map('v', '<leader>B', function()
  vim.api.nvim_feedkeys(Keys '!bash<CR>', 'n', true)
end, { desc = 'Run current line as bash command' })

map('n', '<leader>T', function()
  vim.api.nvim_feedkeys(Keys 'V!title<CR>', 'n', true)
end, { desc = 'Run current line as bash command' })

map('v', '<leader>T', function()
  vim.api.nvim_feedkeys(Keys '!title<CR>', 'n', true)
end, { desc = 'Run current line as bash command' })

map({ 'v', 'n' }, '<leader>I', function()
  require('c.functions.issues').open_selected_issue()
end, { desc = 'Open Jira Issue in current selection' })

map({ 'v' }, '<leader>G', function()
  require('c.functions.google').google_search()()
end, { desc = 'Search current selected string with google' })

-- get current line to variable

-- run current line as lua command in vim
map('n', '<leader>V', function()
  ---@diagnostic disable-next-line: param-type-mismatch
  local line = vim.fn.getline '.'
  vim.api.nvim_feedkeys(Keys(':lua ' .. line .. '<CR>'), 'n', true)
end, { desc = 'Run current line as vim command' })

local track_position_before_relative_jump = require 'c.functions.relative_jump'
map('n', 'k', track_position_before_relative_jump.up)
map('n', 'j', track_position_before_relative_jump.down)

map('n', 'gv', function()
  vim.api.nvim_feedkeys(Keys '<c-w>v', 'n', true)
  require('telescope.builtin').lsp_definitions { reuse_win = true }
end, { desc = 'Split vertical and go to definition' })

map('n', 'gs', function()
  vim.api.nvim_feedkeys(Keys '<c-w>s', 'n', true)
  require('telescope.builtin').lsp_definitions { reuse_win = true }
end, { desc = 'Split vertical and go to definition' })

map('n', '<leader><C-Space>', function()
  local today = os.date '%Y-%m-%d'
  local notes_dir = os.getenv 'DAILY'
  vim.cmd('e ' .. notes_dir .. '/' .. today .. '.md')
end, { desc = 'Open todays note' })

local surround_map = require('c.functions.surround').surround_map
surround_map({ '(', ')' }, '(')
surround_map({ '[', ']' }, '[')
surround_map({ '"' }, '"')
surround_map({ "'" }, "'")
surround_map({ '`' }, '`')
surround_map({ '<leader>b', '<C-b>' }, '**')
surround_map({ '<leader>i', '<C-_>' }, '_')
surround_map({ '<leader>~' }, '~~')
