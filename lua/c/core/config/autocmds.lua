local function augroup(name)
  return vim.api.nvim_create_augroup('my_autocmd-' .. name, { clear = true })
end

vim.api.nvim_create_autocmd({ 'VimEnter' }, {
  callback = function()
    vim.cmd 'setlocal formatoptions-=cro' -- Stop comment continuation on line below
  end,
  group = augroup 'AllFilesGroup',
  desc = 'Run on all files',
})

vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})

-- JSON --------------------------------------------------------------

vim.api.nvim_create_autocmd({ 'FileType' }, {
  pattern = 'json',
  callback = function()
    vim.o.conceallevel = 3
  end,
  group = augroup 'JSONGroup',
  desc = 'Run when entering JSON files',
})

-- wrap and check for spell in text filetypes
vim.api.nvim_create_autocmd('FileType', {
  group = augroup 'wrap_spell',
  pattern = { 'gitcommit', 'markdown' },
  callback = function()
    vim.opt_local.wrap = true
    vim.opt_local.spell = true
  end,
})

-- tmux

local wr_group = vim.api.nvim_create_augroup('WinResize', { clear = true })

vim.api.nvim_create_autocmd('VimResized', {
  group = wr_group,
  pattern = '*',
  command = 'wincmd =',
  desc = 'Automatically resize windows when the host window size changes.',
})

-- markdown
-- vim.api.nvim_create_autocmd({ 'VimEnter' }, {
--   pattern = 'new_note',
--   callback = function()
--     require('c.functions').set_colorscheme(vim.g.pretty_colorscheme)
--     vim.api.nvim_feedkeys(Keys 'ggi<BS><BS><BS>', 'n', true)
--   end,
--   group = augroup 'new-note',
--   desc = 'Run when entering new_note files',
-- })
--

-- insert mode when entering git commit
vim.api.nvim_create_autocmd('VimEnter', {
  group = augroup 'git-commit-augroup',
  pattern = { 'COMMIT_EDITMSG' },
  callback = function()
    vim.api.nvim_feedkeys(Keys 'i<BS>', 'n', true)
  end,
})
