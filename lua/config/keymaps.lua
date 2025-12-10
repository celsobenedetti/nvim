-- TODO: table driven config
-- Save file
map({ 'x', 'n', 'i', 's' }, '<C-s>', '<cmd>w<cr><esc>', { desc = 'Save File' })

-- lazy
map('n', '<leader>l', '<cmd>Lazy<cr>', { desc = 'Lazy' })

-- tabs
map('n', ']<tab>', ':tabnext<CR>', { desc = 'tab: next' })
map('n', '[<tab>', ':tabprevious<CR>', { desc = 'tab: prev' })
map('n', '<leader><tab>n', ':tabnew<CR>', { desc = 'tab: new' })

-- better j/k
local jump = require 'lib.jump'
map('n', 'k', jump.up)
map('n', 'j', jump.down)

-- h/l with folding
local fold = require 'lib.fold'
map('n', 'h', fold.h, { desc = 'h: move left or fold' })
map('n', 'l', fold.l, { desc = 'l: move right and unfold' })

map('n', '<leader>re', function()
  vim.cmd ':w'
  vim.cmd ':e! %'
end, { desc = 'write and refresh buffer' })

-- fs
local fs = require 'lib.fs'
map('n', '<leader>mv', fs.mv_file, { desc = 'Move file of current buffer to dir' })

map({ 'i', 'n', 's' }, '<esc>', function()
  vim.cmd 'noh'
  return '<esc>'
end, { expr = true, desc = 'Escape and Clear hlsearch' })

map('n', '<leader>yy', function()
  local file = vim.fn.expand '%:p'
  vim.cmd('silent !wl-copy ' .. file, { silent = true }) -- wayland
  Snacks.notify('Copied to clipboard: ' .. file)
end, { desc = 'Copy file path to clipboard' })
