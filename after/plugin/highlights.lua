if vim.g.colorscheme == 'default' then
  return
end

local colors = require('lib.colors')
vim.api.nvim_set_hl(0, 'MsgArea', { link = vim.g.hl.text_secondary }) -------- transparency changes -----------

vim.api.nvim_set_hl(0, 'TextSecondary', { fg = vim.g.colors.secondary or vim.g.colors.fg })

if vim.g.colors.colorcolumn then
  vim.api.nvim_set_hl(0, 'ColorColumn', { bg = vim.g.colors.colorcolumn })
end


-- stylua: ignore start
-- vim.api.nvim_set_hl( 0, 'TabLine', { bg = colors.get_color('StatusLine', 'bg'), fg = colors.get_color(vim.g.hl.text.subtext, 'fg') })
-- vim.api.nvim_set_hl(0, 'TabLineFill', { bg = colors.get_color('StatusLine', 'bg') })
-- vim.api.nvim_set_hl(0, 'TabLineSel', { bg = colors.get_color('StatusLine', 'bg') , bold = true, underline=true})
vim.api.nvim_set_hl(0, 'NonText', { link = "Comment"})
-- vim.api.nvim_set_hl(0, 'Folded', { bg = 'none' })
vim.api.nvim_set_hl(0, 'FlashMatch', { link = 'MiniHipatternsNote' })
vim.api.nvim_set_hl(0, 'BlinkCmpMenuBorder', { bg = 'none' })

local hyperlink = { underline = true, fg = colors.get_color('@markup.link.label.markdown_inline', 'fg') }
vim.api.nvim_set_hl(0, '@markup.link.label.markdown_inline', hyperlink)
vim.api.nvim_set_hl(0, '@org.hyperlink.desc.org', hyperlink)
-- stylua: ignore end

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

-- necessary since "laststatus=3", and "laststatus=0" render statuslien between panes
-- vim.api.nvim_set_hl(0, 'StatusLine', { bg = 'none', fg = colors.get_color('StatusLine', 'fg') })
vim.api.nvim_set_hl(0, 'WinSeparator', { bg = 'none', fg = colors.get_color('WinSeparator', 'fg') })
vim.api.nvim_set_hl(0, 'StatusLine', { link = 'WinSeparator' })
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

if vim.g.colors.folded then
  vim.api.nvim_set_hl(0, 'Folded', { bg = vim.g.colors.folded })
end
