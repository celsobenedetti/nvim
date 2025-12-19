-- Save file
map({ 'x', 'n', 'i', 's' }, '<C-s>', '<cmd>silent w<cr><esc>', { desc = 'Save File' })

-- lazy
map('n', '<leader>l', '<cmd>Lazy<cr>', { desc = 'Lazy' })

-- tabs
map('n', ']<tab>', ':tabnext<CR>', { desc = 'tab: next' })
map('n', '[<tab>', ':tabprevious<CR>', { desc = 'tab: prev' })
map('n', '<leader><tab>n', ':tabnew<CR>', { desc = 'tab: new' })

-- better j/k
local jump = require('lib.jump')
map('n', 'k', jump.up)
map('n', 'j', jump.down)

-- h/l with folding
local fold = require('lib.fold')
map('n', 'h', fold.h, { desc = 'h: move left or fold' })
map('n', 'l', fold.l, { desc = 'l: move right and unfold' })

map('n', '<leader>R', function()
  vim.cmd(':w')
  vim.cmd(':e! %')
end, { desc = 'write and refresh buffer' })

-- fs
local fs = require('lib.fs')
map('n', '<leader>mv', fs.mv_file, { desc = 'Move file of current buffer to dir' })

map({ 'i', 'n', 's' }, '<esc>', function()
  vim.cmd('noh')
  return '<esc>'
end, { expr = true, desc = 'Escape and Clear hlsearch' })

map('n', 'gy', function()
  local file = vim.fn.expand('%:p')
  vim.cmd('silent !wl-copy ' .. file, { silent = true }) -- wayland
  Snacks.notify('Copied to clipboard: ' .. file)
end, { desc = 'Copy file path to clipboard' })

map('n', '<leader>B', function()
  local conform = require('conform')
  vim.cmd('.!bash')
  vim.schedule(conform.format)
end, { desc = 'Run current line as bash command' })

map({ 'n', 'x', 'v' }, '<leader>sw', function()
  Snacks.picker.grep_word()
end, { desc = 'Visual selection or word (Root Dir)' })
map({ 'n', 'x', 'v' }, '<leader>sW', function()
  Snacks.picker.grep_word({ root = false })
end, { desc = 'Visual selection or word (Root Dir)' })

-- gx
local gx = require('lib.gx')
map('n', 'gx', gx.normal, { desc = 'gx: open link', buffer = true })
map('v', 'gx', gx.visual, { desc = 'gx: open link', buffer = true })
