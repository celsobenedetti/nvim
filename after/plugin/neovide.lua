if not vim.g.neovide then
  return
end

state.statusline_show_time = true

vim.keymap.set(
  { 'n', 'v' },
  '<C-=>',
  ':lua vim.g.neovide_scale_factor = vim.g.neovide_scale_factor + 0.1<CR>',
  { desc = 'neovide: increment scale factor (zoom in)' }
)
vim.keymap.set(
  { 'n', 'v' },
  '<C-->',
  ':lua vim.g.neovide_scale_factor = vim.g.neovide_scale_factor - 0.1<CR>',

  { desc = 'neovide: decrement scale factor (zoom out)' }
)
vim.keymap.set(
  { 'n', 'v' },
  '<C-0>',
  ':lua vim.g.neovide_scale_factor = 1<CR>',
  { desc = 'neovide: reset scale factor' }
)

vim.keymap.set({ 'n', 'i', 'v', 'c', 't' }, '<C-S-v>', function()
  vim.api.nvim_paste(vim.fn.getreg('+'), true, -1)
end, { silent = true, desc = 'neovide: paste with ctrl+shift+v to match term ergonomics' })

lib.notes.focus_or_create_notes_tab(function()
  vim.cmd(':Org agenda a')
end)
