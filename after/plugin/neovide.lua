if not vim.g.neovide then
  return
end

vim.g.neovide_padding_top = 1
vim.g.neovide_padding_bottom = 0
vim.g.neovide_padding_right = 0
vim.g.neovide_padding_left = 5

local cwd = require('lib.cwd')

vim.keymap.set('n', '<C-S-E>', function()
  if vim.bo.filetype == 'snacks_picker_list' then
    vim.cmd('q')
    return
  end
  Snacks.picker.resume('explorer')
end, { desc = 'Snacks: explorer' })

map('n', '<C-S-O>', function()
  vim.cmd('Namu symbols')
end, { desc = 'LSP Symbols' })

map({ 'n', 't' }, '<C-/>', function()
  Snacks.terminal(nil, { cwd = cwd.root() })
end, { desc = 'Terminal (Root Dir)' })

-- write and close all buffers, but don't quit neovide
map({ 'n' }, 'ZZ', function()
  if vim.bo.filetype == 'markdown' or vim.bo.filetype == 'sidekick_terminal' or vim.bo.filetype == 'gitcommit' then
    vim.api.nvim_feedkeys(Keys('ZZ'), 'n', false)
    return
  end
  vim.cmd('wa')
  Snacks.bufdelete.all()
end, { desc = 'Terminal (Root Dir)' })

-- paste the same way as the terminal
vim.keymap.set({ 'n', 'v', 's', 'x', 'o', 'i', 'l', 'c', 't' }, '<C-S-v>', function()
  vim.api.nvim_paste(vim.fn.getreg('+'), true, -1)
end, { noremap = true, silent = true })
