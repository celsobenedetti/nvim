local colors = require('lib.colors')
vim.api.nvim_set_hl(0, 'MsgArea', { link = vim.g.hl.text_secondary }) -------- transparency changes -----------

-- vim.api.nvim_set_hl(0, 'StatusLine', { bg = 'none' })
vim.api.nvim_set_hl(
  0,
  'TabLine',
  { bg = colors.get_color('StatusLine', 'bg'), fg = colors.get_color(vim.g.hl.subtext, 'fg') }
)
vim.api.nvim_set_hl(0, 'TabLineFill', { bg = colors.get_color('StatusLine', 'bg') })
vim.api.nvim_set_hl(
  0,
  'TabLineSel',
  { bg = colors.get_color('BlinkCmpMenuBorder', 'fg'), fg = colors.get_color(vim.g.hl.text_secondary, 'fg') }
)

if vim.g.neovide then
  return
end

vim.api.nvim_set_hl(0, 'Normal', { bg = 'none' })
vim.api.nvim_set_hl(0, 'NormalFloat', { bg = 'none' })
vim.api.nvim_set_hl(0, 'FloatBorder', { bg = 'none' })
vim.api.nvim_set_hl(0, 'Pmenu', { bg = 'none' })
vim.api.nvim_set_hl(0, 'Terminal', { bg = 'none' })
vim.api.nvim_set_hl(0, 'EndOfBuffer', { bg = 'none' })
vim.api.nvim_set_hl(0, 'FoldColumn', { bg = 'none' })
vim.api.nvim_set_hl(0, 'Folded', { bg = 'none' })
vim.api.nvim_set_hl(0, 'SignColumn', { bg = 'none' })
vim.api.nvim_set_hl(0, 'NormalNC', { bg = 'none' })
vim.api.nvim_set_hl(0, 'WhichKeyFloat', { bg = 'none' })
vim.api.nvim_set_hl(0, 'TelescopeBorder', { bg = 'none' })
vim.api.nvim_set_hl(0, 'TelescopeNormal', { bg = 'none' })
vim.api.nvim_set_hl(0, 'TelescopePromptBorder', { bg = 'none' })
vim.api.nvim_set_hl(0, 'TelescopePromptTitle', { bg = 'none' })

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
