if not vim.g.neovide then
  return
end

vim.g.fn.rename_tab(vim.g.notes_tabname)

if os.getenv('NVIM_STARTUP_ORG_AGENDA_TODAY') then
  pcall(require, os.getenv('NVIM_STARTUP_ORG_AGENDA_TODAY'))
end
