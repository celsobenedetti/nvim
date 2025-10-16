-- https://github.com/mhinz/vim-galore#saner-behavior-of-n-and-n
map('n', 'n', "'Nn'[v:searchforward].'zv'", { expr = true, desc = 'Next search result' })
map('x', 'n', "'Nn'[v:searchforward]", { expr = true, desc = 'Next search result' })
map('o', 'n', "'Nn'[v:searchforward]", { expr = true, desc = 'Next search result' })
map('n', 'N', "'nN'[v:searchforward].'zv'", { expr = true, desc = 'Prev search result' })
map('x', 'N', "'nN'[v:searchforward]", { expr = true, desc = 'Prev search result' })
map('o', 'N', "'nN'[v:searchforward]", { expr = true, desc = 'Prev search result' })

map('t', '<esc><esc>', '<C-\\><C-n>', { desc = 'Escape insert mode in terminal' }) -- let me escape insert in terminal!

map('n', ']<tab>', ':tabnext<CR>', { desc = 'tab: next' })
map('n', '[<tab>', ':tabprevious<CR>', { desc = 'tab: prev' })
map('n', '<leader><tab>n', ':tabnew<CR>', { desc = 'tab: new' })
