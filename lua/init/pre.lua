-- Code to run before lazy.nvim starts loading plugins

if lib.cwd.matches({ 'notes' }) then
  lib.tab.rename(config.tabs.notes)
  vim.cmd.lcd(config.dirs.notes)
end
