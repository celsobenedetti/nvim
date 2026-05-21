---@module notes autocmds
---@description code to run when opening neovim in notes repository

if not require('lib.cwd').matches({ 'notes' }) then
  return
end

vim.g.fn.rename_tab(vim.g.icons.notes .. 'notes')
