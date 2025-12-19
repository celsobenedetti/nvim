if not vim.g.neovide then
  return
end

vim.g.neovide_padding_top = 1
vim.g.neovide_padding_bottom = 0
vim.g.neovide_padding_right = 0
vim.g.neovide_padding_left = 5

map('n', '<C-S-O>', function()
  vim.cmd('Namu symbols')
end, { desc = 'LSP Symbols' })

map('n', '<C-S-R>', function()
  vim.cmd('OverseerToggle')
end, { desc = 'Overseer toggle' })

-- paste the same way as the terminal
vim.keymap.set({ 'n', 'v', 's', 'x', 'o', 'i', 'l', 'c', 't' }, '<C-S-v>', function()
  vim.api.nvim_paste(vim.fn.getreg('+'), true, -1)
end, { noremap = true, silent = true })

-- write and close all buffers, but don't quit neovide
local function close_all_buffers()
  if vim.bo.filetype == 'markdown' or vim.bo.filetype == 'sidekick_terminal' or vim.bo.filetype == 'gitcommit' then
    vim.api.nvim_feedkeys(Keys('ZZ'), 'n', false)
    return
  end
  vim.cmd('wa')
  Snacks.bufdelete.all()
  vim.cmd('tabonly', { silent = true })
  vim.defer_fn(function()
    vim.cmd('LspRestart')
  end, 1500)
end

map({ 'n' }, 'ZZ', close_all_buffers, { desc = 'Terminal (Root Dir)' })
map({ 'n' }, 'ZQ', close_all_buffers, { desc = 'Terminal (Root Dir)' })
