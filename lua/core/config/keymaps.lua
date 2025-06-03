-- new file
map('n', '<leader>R', ':e! %<cr>', { desc = 'Refresh Buffer' })
-- map('n', '<leader>dd', ':Bdelete<cr>', { desc = 'Delete Buffer' }) -- replaced with snacks.bufdelete
map('n', '<leader><tab>', ':tabnext<cr>', { desc = 'Next Tab' })
map('n', 'ZQ', ':qa!<CR>', { desc = 'Quit all' })
map('n', '<leader>on', ':only<CR>', { desc = "':only' alias" })

-- fold on tab
map('n', '<tab>', 'za', { desc = 'toggle fold' })

map('n', '[g', ':Gitsigns prev_hunk<CR>', { desc = 'Prev git diff hunk' })
map('n', ']g', ':Gitsigns next_hunk<CR>', { desc = 'Next git diff hunk' })

map('n', '<leader>oo', require 'functions.open_orgmode_or_obsidian_link', { desc = 'Open orgmode or obsidian link' })

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

--- Web keymaps
map({ 'v', 'n' }, '<leader>I', require('lib.utils.web').open_selected_issue, { desc = 'Open Jira Issue in current selection' })
map({ 'v' }, '<leader>gs', require('lib.utils.web').google_search, { desc = 'Search current selected string with google' })

-- run current line as lua command in vim
map({ 'n', 'v' }, '<leader>L', function()
  local current_line = vim.fn.getline '.'
  vim.api.nvim_feedkeys(Keys(':lua ' .. current_line .. '<CR>'), 'n', true)
end, { desc = 'Run current line as vim command' })

local track_position_before_relative_jump = require 'functions.relative_jump'
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

local surround_map = require('functions.surround').surround_map
surround_map({ '(', ')' }, '(')
surround_map({ '[', ']' }, '[')
surround_map({ '"' }, '"')
surround_map({ "'" }, "'")
surround_map({ '`' }, '`')
surround_map({ '<leader>b', '<C-b>' }, '**')
surround_map({ '<leader>i', '<C-_>' }, '_')
-- surround_map({ '<leader>~' }, '~~')
--
--
