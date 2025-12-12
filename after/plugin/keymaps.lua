-- Save file
map({ 'x', 'n', 'i', 's' }, '<C-s>', '<cmd>w<cr><esc>', { desc = 'Save File' })

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

-- toggles
-- stylua: ignore start
local toggle = require('lib.toggle')
map('n', '<leader>tc', toggle.completion, { desc = 'toggle: completion' })
map('n', '<leader>ts', toggle.supermaven, { desc = 'toggle: supermaven' })
map('n', '<leader>tf', toggle.autoformat, { desc = 'toggle: autoformat' })
Snacks.toggle.option("spell", { name = "Spelling" }):map("<leader>us")
Snacks.toggle.option("wrap", { name = "Wrap" }):map("<leader>uw")
Snacks.toggle.option("relativenumber", { name = "Relative Number" }):map("<leader>ur")
Snacks.toggle.diagnostics():map("<leader>ud")
Snacks.toggle.line_number():map("<leader>ul")
Snacks.toggle.option("conceallevel", { off = 0, on = vim.o.conceallevel > 0 and vim.o.conceallevel or 2, name = "Conceal Level" }):map("<leader>uc")
Snacks.toggle.option("showtabline", { off = 0, on = vim.o.showtabline > 0 and vim.o.showtabline or 2, name = "Tabline" }):map("<leader>uA")
Snacks.toggle.treesitter():map("<leader>uT")
Snacks.toggle.option("background", { off = "light", on = "dark" , name = "Dark Background" }):map("<leader>ub")
Snacks.toggle.dim():map("<leader>uD")
Snacks.toggle.animate():map("<leader>ua")
Snacks.toggle.scroll():map("<leader>uS")
Snacks.toggle.indent():map("<leader>ug")
Snacks.toggle.profiler():map("<leader>dpp")
Snacks.toggle.profiler_highlights():map("<leader>dph")
-- stylua: ignore end

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
