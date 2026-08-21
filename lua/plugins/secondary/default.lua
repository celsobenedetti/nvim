if 'default' ~= state.omarchy_colorscheme.colorscheme then
  return {}
end

vim.api.nvim_set_hl(0, '@markup.strong', { fg = '#f4d88c', bold = true })
vim.api.nvim_set_hl(0, 'TabLineSel', { bg = colors.accent, fg = colors.bg })
vim.api.nvim_set_hl(0, '@org.priority.highest', { bg = colors.color3, fg = colors.bg })
vim.api.nvim_set_hl(0, '@org.agenda.scheduled_past', { fg = colors.color2 })

vim.api.nvim_set_hl(0, '@markup.heading.1.markdown', { fg = colors.color1, bold = true })
vim.api.nvim_set_hl(0, '@markup.heading.2.markdown', { fg = colors.color2, bold = true })
vim.api.nvim_set_hl(0, '@markup.heading.3.markdown', { fg = colors.color3, bold = true })
vim.api.nvim_set_hl(0, '@markup.heading.4.markdown', { fg = colors.color4, bold = true })
vim.api.nvim_set_hl(0, '@markup.heading.5.markdown', { fg = colors.color5, bold = true })
vim.api.nvim_set_hl(0, '@markup.heading.6.markdown', { fg = colors.color6, bold = true })

lib.colors.update({
  done = colors.color4,
  links = '#83efef',
  folded = '#1C2225',
  colorcolumn = '#1C2225',
})

return {}
