local map = vim.keymap.set

-- new file
map('n', '<leader>fn', '<cmd>enew<cr>', { desc = 'New File' })
map('n', '<leader>re', '<cmd>e %<cr>', { desc = 'Refresh Buffer' })

map('n', 'g[', '<cmd>Gitsigns prev_hunk<CR>', { desc = 'Prev git diff hunk' })
map('n', 'g]', '<cmd>Gitsigns next_hunk<CR>', { desc = 'Next git diff hunk' })

-- Commands

map('n', '<leader>G', '<cmd>ChatGPT<CR>', { desc = 'Open ChatGPT' })
map('n', '<leader>C', '<cmd>Clip<CR>', { desc = 'Copy file path to clipboard' })
map('n', '<leader>D', '<cmd>Diff<CR>', { desc = 'Open tmux popup for with current file diff' })
map('n', '<leader>L', '<cmd>Log<CR>', { desc = 'Open tmux popup for git log' })
map('n', '<leader>gl', '<cmd>Glow<CR>', { desc = 'Open tmux popup for git log' })
map('n', '<leader>n', '<cmd>Note<CR>', { desc = 'Run bash on current line' })

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

local track_position_before_relative_jump = require 'functions.relative_jump'
map('n', 'k', track_position_before_relative_jump.up)
map('n', 'j', track_position_before_relative_jump.down)

map('n', 'gv', function()
  vim.api.nvim_feedkeys(Keys '<c-w>v', 'n', true)
  require('telescope.builtin').lsp_definitions { reuse_win = true }
end, { desc = 'Split vertical and go to definition' })

--- toggles

map('n', '<leader>ud', require('functions.toggle').diagnostics, { desc = 'Toggle diagnostics' })

local conceallevel = vim.o.conceallevel > 0 and vim.o.conceallevel or 3
map('n', '<leader>uC', function()
  require('functions.toggle').option { option = 'conceallevel', silent = false, values = { 0, conceallevel } }
end, { desc = 'Toggle diagnostics' })

map('n', '<leader>us', function()
  require('functions.toggle').option { option = 'spell' }
end, { desc = 'Toggle Spelling' })

map('n', '<leader>uf', function()
  require('functions.toggle').format()
end, { desc = 'Toggle auto format (global)' })
