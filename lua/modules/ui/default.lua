local lib = {
  colors = require('lib.colors'),
}

if 'default' ~= lib.colors.omarchy_colorscheme().colorscheme then
  return {}
end

vim.api.nvim_set_hl(0, 'TabLineSel', { bg = vim.g.colors.accent, fg = vim.g.colors.bg })
vim.api.nvim_set_hl(0, '@org.priority.highest', { bg = vim.g.colors.color3, fg = vim.g.colors.bg })

lib.colors.update({
  links = '#83efef',
})

return {}
