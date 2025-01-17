function Augroup(name)
  return vim.api.nvim_create_augroup('Custom_Augroup_' .. name, { clear = true })
end

vim.api.nvim_create_autocmd({ 'VimEnter' }, {
  callback = function()
    vim.cmd 'setlocal formatoptions-=cro' -- Stop comment continuation on line below
  end,
  group = Augroup 'Run_on_VimEnter',
  desc = 'Run on all files',
})

vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = Augroup 'Highlight_on_Yank',
  callback = function()
    vim.highlight.on_yank()
  end,
})

--- Used for tmux pane resizing
vim.api.nvim_create_autocmd('VimResized', {
  group = Augroup 'Resize_Windows',
  pattern = '*',
  command = 'wincmd =',
  desc = 'Automatically resize windows when the host window size changes.',
})

-- insert mode when entering git commit
vim.api.nvim_create_autocmd('VimEnter', {
  group = Augroup 'Git_Commit_Editor',
  pattern = { 'COMMIT_EDITMSG', 'new_note' },
  callback = function()
    vim.api.nvim_feedkeys(Keys 'i<BS>', 'n', true)
  end,
})
