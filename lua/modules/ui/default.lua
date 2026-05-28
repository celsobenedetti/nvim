local lib = {
  colors = require('lib.colors'),
}

if 'default' ~= lib.colors.omarchy_colorscheme().colorscheme then
  return {}
end

vim.api.nvim_set_hl(0, 'TabLineSel', { bg = vim.g.colors.accent, fg = vim.g.colors.bg })
vim.api.nvim_set_hl(0, '@org.priority.highest', { bg = vim.g.colors.color3, fg = vim.g.colors.bg })
vim.api.nvim_set_hl(0, '@markup.heading.1.markdown', { fg = vim.g.colors.color1, bold = true })
vim.api.nvim_set_hl(0, '@markup.heading.2.markdown', { fg = vim.g.colors.color2, bold = true })
vim.api.nvim_set_hl(0, '@markup.heading.3.markdown', { fg = vim.g.colors.color3, bold = true })
vim.api.nvim_set_hl(0, '@markup.heading.4.markdown', { fg = vim.g.colors.color4, bold = true })
vim.api.nvim_set_hl(0, '@markup.heading.5.markdown', { fg = vim.g.colors.color5, bold = true })
vim.api.nvim_set_hl(0, '@markup.heading.6.markdown', { fg = vim.g.colors.color6, bold = true })

lib.colors.update({
  links = '#83efef',
})

return {}
