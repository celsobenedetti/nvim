-- https://github.com/mhinz/vim-galore#saner-behavior-of-n-and-n
vim.keymap.set('n', 'n', "'Nn'[v:searchforward].'zv'", { expr = true, desc = 'Next search result' })
vim.keymap.set('x', 'n', "'Nn'[v:searchforward]", { expr = true, desc = 'Next search result' })
vim.keymap.set('o', 'n', "'Nn'[v:searchforward]", { expr = true, desc = 'Next search result' })
vim.keymap.set('n', 'N', "'nN'[v:searchforward].'zv'", { expr = true, desc = 'Prev search result' })
vim.keymap.set('x', 'N', "'nN'[v:searchforward]", { expr = true, desc = 'Prev search result' })
vim.keymap.set('o', 'N', "'nN'[v:searchforward]", { expr = true, desc = 'Prev search result' })

vim.keymap.set('x', 'p', '"_dP', { desc = 'Paste without losing register' }) --hold on to register when pasting and replace text

vim.keymap.set('i', '<C-e>', '<Esc>A', { remap = true })
vim.keymap.set('i', '<C-a>', '<Esc>I', { remap = true })

-- sensible terminal mappings
vim.keymap.set('t', '<esc><esc>', '<C-\\><C-n>') -- let me escape insert in terminal!
vim.keymap.set('t', '<C-w>', '<C-\\><C-n><C-w>') -- make C-w commands work like usual in the terminal
vim.keymap.set('t', '', '<C-\\><C-n>')         -- C-6 alternate file

-- -- Move Lines  -- replaced by mini.move
-- map('n', '<A-j>', "<cmd>execute 'move .+' . v:count1<cr>==", { desc = 'Move Down' })
-- map('n', '<A-k>', "<cmd>execute 'move .-' . (v:count1 + 1)<cr>==", { desc = 'Move Up' })
-- map('i', '<A-j>', '<esc><cmd>m .+1<cr>==gi', { desc = 'Move Down' })
-- map('i', '<A-k>', '<esc><cmd>m .-2<cr>==gi', { desc = 'Move Up' })
-- map('v', '<A-j>', ":<C-u>execute \"'<,'>move '>+\" . v:count1<cr>gv=gv", { desc = 'Move Down' })
-- map('v', '<A-k>', ":<C-u>execute \"'<,'>move '<-\" . (v:count1 + 1)<cr>gv=gv", { desc = 'Move Up' })

-- commenting
vim.keymap.set('n', 'gco', 'o<esc>Vcx<esc><cmd>normal gcc<cr>fxa<bs>', { desc = 'Add Comment Below' })
vim.keymap.set('n', 'gcO', 'O<esc>Vcx<esc><cmd>normal gcc<cr>fxa<bs>', { desc = 'Add Comment Above' })

-- better indenting
vim.keymap.set('x', '<', '<gv')
vim.keymap.set('x', '>', '>gv')

-- Resize window using <ctrl> arrow keys
vim.keymap.set({ 'n', 't' }, '<C-Up>', '<cmd>resize +2<cr>', { desc = 'Increase Window Height' })
vim.keymap.set({ 'n', 't' }, '<C-Down>', '<cmd>resize -2<cr>', { desc = 'Decrease Window Height' })
vim.keymap.set({ 'n', 't' }, '<C-Left>', '<cmd>vertical resize -2<cr>', { desc = 'Decrease Window Width' })
vim.keymap.set({ 'n', 't' }, '<C-Right>', '<cmd>vertical resize +2<cr>', { desc = 'Increase Window Width' })

if not os.getenv('TMUX') then
  -- Move to window using the <ctrl> hjkl keys
  vim.keymap.set({ 'n', 'i', 't' }, '<C-h>', '<C-w>h', { desc = 'Go to Left Window', remap = true })
  vim.keymap.set({ 'n', 'i', 't' }, '<C-j>', '<C-w>j', { desc = 'Go to Lower Window', remap = true })
  vim.keymap.set({ 'n', 'i', 't' }, '<C-k>', '<C-w>k', { desc = 'Go to Upper Window', remap = true })
  vim.keymap.set({ 'n', 't' }, '<C-l>', '<C-w>l', { desc = 'Go to Right Window', remap = true })
end
