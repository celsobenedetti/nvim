-- new file
map('n', '<leader>R', ':e! %<cr>', { desc = 'Refresh Buffer' })
-- map('n', '<leader>dd', ':Bdelete<cr>', { desc = 'Delete Buffer' }) -- replaced with snacks.bufdelete
map('n', '<leader><tab>', ':tabnext<cr>', { desc = 'Next Tab' })
map('n', '<leader>tn', ':tabnew<cr>', { desc = 'New Tab (:tabnew)' })
map('n', 'ZQ', ':qa!<CR>', { desc = 'Quit all' })
map('n', '<leader>on', ':only<CR>', { desc = "':only' alias" })

-- map jk to escape
map('i', 'jk', '<ESC>')

-- tabs
map('n', '<leader>td', ':tabclose<CR>', { desc = ':tabdelete (tabclose)' })
map('n', '<leader>tc', ':tabclose<CR>', { desc = ':tabdelete (tabclose)' })

-- folds
-- BUG: ghostty doesn't know the difference between <TAB> and <C-i>
-- map('n', '<c-i>', '<c-i>', { desc = 'toggle fold' })
-- map('n', '<TAB>', 'za', { desc = 'toggle fold' })
map('n', '<leader>f+', function()
  vim.o.foldlevel = vim.o.foldlevel - 1
end, { desc = 'increase fold level' })
map('n', '<leader>f-', function()
  vim.o.foldlevel = vim.o.foldlevel + 1
end, { desc = 'decrease fold level' })

map('n', '[g', ':Gitsigns prev_hunk<CR>', { desc = 'Prev git diff hunk' })
map('n', ']g', ':Gitsigns next_hunk<CR>', { desc = 'Next git diff hunk' })

map('n', '<leader>oo', function()
  require 'lib.functions.open_orgmode_or_obsidian_link'()
end, { desc = 'Open orgmode or obsidian link' })
map('n', '<leader>ov', function()
  vim.cmd 'vsplit'
  require 'lib.functions.open_orgmode_or_obsidian_link'()
end, { desc = 'Open orgmode or obsidian link on vsplit' })

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

local track_position_before_relative_jump = require 'lib.functions.relative_jump'
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

map('n', '<leader>P', function()
  vim.api.nvim_feedkeys(Keys 'vip', 'n', true)
  local file_path = vim.fn.expand '%:p'
  if file_path:find 'html' then
    vim.api.nvim_feedkeys(Keys '!prettier --parser=html<CR>', 'n', true)
  else
    vim.api.nvim_feedkeys(Keys '!prettier --parser=markdown<CR>', 'n', true)
  end
end, { desc = 'Format current paragraph with Prettier' })

map('v', '<leader>P', function()
  local file_path = vim.fn.expand '%:p'
  if file_path:find '.md' then
    vim.api.nvim_feedkeys(Keys '!prettier --parser=markdown<CR>', 'n', true)
  else
    vim.api.nvim_feedkeys(Keys '!prettier --parser=html<CR>', 'n', true)
  end
end, { desc = 'Format current selection with Prettier' })

map('n', '<leader>rm', function()
  vim.api.nvim_feedkeys(Keys ':!rm %<CR>', 'n', true)
  vim.api.nvim_feedkeys(Keys ':bdelete<cr>', 'n', true)
end, { desc = 'rm buffer file' })
