if 'default' ~= require('lib.colors').omarchy_colorscheme().colorscheme then
  return {}
end

vim.api.nvim_set_hl(0, 'TabLineSel', { bg = vim.g.colors.accent, fg = vim.g.colors.bg })
vim.api.nvim_set_hl(0, '@org.priority.highest', { bg = vim.g.colors.color3, fg = vim.g.colors.bg })

return {}
