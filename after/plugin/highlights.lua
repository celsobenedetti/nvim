local colors = lib.colors

if colors.omarchy_colorscheme().colorscheme == 'default' then
  return
end
vim.api.nvim_set_hl(0, 'Bold', { fg = state.colors.fg, bold = true, cterm = { bold = true } })
vim.api.nvim_set_hl(0, 'MsgArea', { link = state.hl.text_secondary }) -------- transparency changes -----------

vim.api.nvim_set_hl(0, 'TextSecondary', { fg = state.colors.secondary or state.colors.fg })

if state.colors.colorcolumn then
  vim.api.nvim_set_hl(0, 'ColorColumn', { bg = state.colors.colorcolumn })
end


-- stylua: ignore start
-- vim.api.nvim_set_hl( 0, 'TabLine', { bg = colors.get_color('StatusLine', 'bg'), fg = colors.get_color(state.hl.text.subtext, 'fg') })
-- vim.api.nvim_set_hl(0, 'TabLineFill', { bg = colors.get_color('StatusLine', 'bg') })
-- vim.api.nvim_set_hl(0, 'TabLineSel', { bg = colors.get_color('StatusLine', 'bg') , bold = true, underline=true})
vim.api.nvim_set_hl(0, 'NonText', { link = "Comment" })
-- vim.api.nvim_set_hl(0, 'Folded', { bg = 'none' })
vim.api.nvim_set_hl(0, 'FlashMatch', { link = 'MiniHipatternsNote' })
vim.api.nvim_set_hl(0, 'BlinkCmpMenuBorder', { bg = 'none' })

local hyperlink = { underline = true, fg = colors.get_color('@markup.link.label.markdown_inline', 'fg') }
vim.api.nvim_set_hl(0, '@markup.link.label.markdown_inline', hyperlink)
vim.api.nvim_set_hl(0, '@org.hyperlink.desc.org', hyperlink)

vim.api.nvim_set_hl(0, 'Normal', { bg = 'none' })
vim.api.nvim_set_hl(0, 'NormalFloat', { bg = 'none' })
vim.api.nvim_set_hl(0, 'FloatBorder', { bg = 'none' })
vim.api.nvim_set_hl(0, 'Pmenu', { bg = 'none' })
vim.api.nvim_set_hl(0, 'Terminal', { bg = 'none' })
vim.api.nvim_set_hl(0, 'EndOfBuffer', { bg = 'none' })
vim.api.nvim_set_hl(0, 'FoldColumn', { bg = 'none' })
vim.api.nvim_set_hl(0, 'SignColumn', { bg = 'none' })
vim.api.nvim_set_hl(0, 'NormalNC', { bg = 'none' })
vim.api.nvim_set_hl(0, 'WhichKeyFloat', { bg = 'none' })

vim.api.nvim_set_hl(0, 'NotifyINFOBody', { bg = 'none' })
vim.api.nvim_set_hl(0, 'NotifyERRORBody', { bg = 'none' })
vim.api.nvim_set_hl(0, 'NotifyWARNBody', { bg = 'none' })
vim.api.nvim_set_hl(0, 'NotifyTRACEBody', { bg = 'none' })
vim.api.nvim_set_hl(0, 'NotifyDEBUGBody', { bg = 'none' })
vim.api.nvim_set_hl(0, 'NotifyINFOTitle', { bg = 'none' })
vim.api.nvim_set_hl(0, 'NotifyERRORTitle', { bg = 'none' })
vim.api.nvim_set_hl(0, 'NotifyWARNTitle', { bg = 'none' })
vim.api.nvim_set_hl(0, 'NotifyTRACETitle', { bg = 'none' })
vim.api.nvim_set_hl(0, 'NotifyDEBUGTitle', { bg = 'none' })
vim.api.nvim_set_hl(0, 'NotifyINFOBorder', { bg = 'none' })
vim.api.nvim_set_hl(0, 'NotifyERRORBorder', { bg = 'none' })
vim.api.nvim_set_hl(0, 'NotifyWARNBorder', { bg = 'none' })
vim.api.nvim_set_hl(0, 'NotifyTRACEBorder', { bg = 'none' })
vim.api.nvim_set_hl(0, 'NotifyDEBUGBorder', { bg = 'none' })

vim.api.nvim_set_hl(0, 'CursorLineNr', { bg = 'none', fg = colors.get_color('CursorLineNr', 'fg') })
vim.api.nvim_set_hl(0, 'LineNr', { bg = 'none', fg = colors.get_color('LineNr', 'fg') })
vim.api.nvim_set_hl(0, 'GitSignsAdd', { bg = 'none', fg = colors.get_color('GitSignsAdd', 'fg') })
vim.api.nvim_set_hl(0, 'GitSignsChange', { bg = 'none', fg = colors.get_color('GitSignsChange', 'fg') })
vim.api.nvim_set_hl(0, 'GitSignsDelete', { bg = 'none', fg = colors.get_color('GitSignsDelete', 'fg') })

vim.api.nvim_set_hl(0, 'TroubleNormal', { bg = 'none', fg = colors.get_color('TroubleNormal', 'fg') })
vim.api.nvim_set_hl(0, 'PmenuSbar', { bg = 'none', fg = colors.get_color('PmenuSbar', 'fg') })
vim.api.nvim_set_hl(0, 'WinBarNC', { bg = 'none', fg = colors.get_color('WinBarNC', 'fg') })
vim.api.nvim_set_hl(0, 'WinBar', { bg = 'none', fg = colors.get_color('WinBar', 'fg') })
vim.api.nvim_set_hl(0, 'FloatTitle', { bg = 'none', fg = colors.get_color('FloatTitle', 'fg') })
vim.api.nvim_set_hl(0, 'SnacksBackdrop', { bg = 'none', fg = colors.get_color('SnacksBackdrop', 'fg') })
vim.api.nvim_set_hl(0, 'SnacksPickerNormal', { bg = 'none', fg = colors.get_color('SnacksPickerNormal', 'fg') })

vim.api.nvim_set_hl(0, 'SnacksPickerCursorLine', { bg = 'none', fg = colors.get_color('SnacksPickerCursorLine', 'fg') })
vim.api.nvim_set_hl(0, 'SnacksPickerListCursorLine',
  { bg = 'none', fg = colors.get_color('SnacksPickerListCursorLine', 'fg') })
vim.api.nvim_set_hl(0, 'SnacksPickerBorder', { bg = 'none', fg = colors.get_color('SnacksPickerBorder', 'fg') })
vim.api.nvim_set_hl(0, 'SnacksPickerListBorder', { bg = 'none', fg = colors.get_color('SnacksPickerListBorder', 'fg') })
vim.api.nvim_set_hl(0, 'SnacksPickerListNormal', { bg = 'none', fg = colors.get_color('SnacksPickerListNormal', 'fg') })
vim.api.nvim_set_hl(0, 'SnacksPickerInputBorder', { bg = 'none', fg = colors.get_color('SnacksPickerInputBorder', 'fg') })
vim.api.nvim_set_hl(0, 'SnacksPickerInputNormal', { bg = 'none', fg = colors.get_color('SnacksPickerInputNormal', 'fg') })
vim.api.nvim_set_hl(0, 'SnacksPickerPreviewBorder',
  { bg = 'none', fg = colors.get_color('SnacksPickerPreviewBorder', 'fg') })
vim.api.nvim_set_hl(0, 'SnacksPickerPreviewNormal',
  { bg = 'none', fg = colors.get_color('SnacksPickerPreviewNormal', 'fg') })

vim.api.nvim_set_hl(0, "SnacksPickerListCursorLine",
  { bg = 'none', fg = colors.get_color('SnacksPickerListCursorLine', 'fg') })
vim.api.nvim_set_hl(0, "SnacksPickerPreviewCursorLine",
  { bg = 'none', fg = colors.get_color('SnacksPickerPreviewCursorLine', 'fg') })
vim.api.nvim_set_hl(0, "SnacksPickerCursorLine", { bg = 'none', fg = colors.get_color('SnacksPickerCursorLine', 'fg') })
vim.api.nvim_set_hl(0, "SnacksPickerCode", { bg = 'none', fg = colors.get_color('SnacksPickerCode', 'fg') })
-- stylua: ignore end

-- necessary since "laststatus=3", and "laststatus=0" render statuslien between panes
-- vim.api.nvim_set_hl(0, 'StatusLine', { bg = 'none', fg = colors.get_color('StatusLine', 'fg') })
vim.api.nvim_set_hl(0, 'WinSeparator', { bg = 'none', fg = colors.get_color('WinSeparator', 'fg') })
-- vim.api.nvim_set_hl(0, 'StatusLine', { link = 'WinSeparator' })
vim.api.nvim_set_hl(0, 'StatusLineNC', { bg = 'none', fg = colors.get_color('StatusLineNC', 'fg') })

vim.api.nvim_set_hl(0, 'SatelliteBar', { bg = 'none', fg = colors.get_color('SatelliteBar', 'fg') })
vim.api.nvim_set_hl(0, 'SatelliteCursor', { bg = 'none', fg = 'none' })
vim.api.nvim_set_hl(0, 'CursorColumn', { bg = 'none', fg = 'none' })

vim.api.nvim_set_hl(0, 'DiagnosticSignError', { bg = 'none', fg = 'none' })
vim.api.nvim_set_hl(0, 'DiagnosticSignHint', { bg = 'none', fg = 'none' })
vim.api.nvim_set_hl(0, 'DiagnosticSignWarn', { bg = 'none', fg = 'none' })
vim.api.nvim_set_hl(0, 'DiagnosticSignOk', { bg = 'none', fg = 'none' })
vim.api.nvim_set_hl(0, 'DiagnosticSignInfo', { bg = 'none', fg = 'none' })

vim.api.nvim_set_hl(
  0,
  '@markup.link.label.markdown_inline',
  { bg = 'none', fg = colors.get_color('@markup.link.label.markdown_inline', 'fg'), italic = true }
)

if state.colors.folded then
  vim.api.nvim_set_hl(0, 'Folded', { bg = state.colors.folded })
end
