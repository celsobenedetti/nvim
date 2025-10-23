local colors = require 'lib.colors'
-- transparent background
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

-- transparent background for neotree
vim.api.nvim_set_hl(0, 'NeoTreeNormal', { bg = 'none' })
vim.api.nvim_set_hl(0, 'NeoTreeNormalNC', { bg = 'none' })
vim.api.nvim_set_hl(0, 'NeoTreeVertSplit', { bg = 'none' })
vim.api.nvim_set_hl(0, 'NeoTreeWinSeparator', { bg = 'none' })
vim.api.nvim_set_hl(0, 'NeoTreeEndOfBuffer', { bg = 'none' })

-- transparent background for nvim-tree
vim.api.nvim_set_hl(0, 'NvimTreeNormal', { bg = 'none' })
vim.api.nvim_set_hl(0, 'NvimTreeVertSplit', { bg = 'none' })
vim.api.nvim_set_hl(0, 'NvimTreeEndOfBuffer', { bg = 'none' })

-- transparent notify background
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

vim.api.nvim_set_hl(0, 'StatusLine', { bg = 'none' })

vim.api.nvim_set_hl(0, 'CursorLineNr', { bg = 'none', fg = colors.get_color('CursorLineNr', 'fg') })
vim.api.nvim_set_hl(0, 'LineNr', { bg = 'none', fg = colors.get_color('LineNr', 'fg') })
vim.api.nvim_set_hl(0, 'GitSignsAdd', { bg = 'none', fg = colors.get_color('GitSignsAdd', 'fg') })
vim.api.nvim_set_hl(0, 'GitSignsChange', { bg = 'none', fg = colors.get_color('GitSignsChange', 'fg') })
vim.api.nvim_set_hl(0, 'GitSignsDelete', { bg = 'none', fg = colors.get_color('GitSignsDelete', 'fg') })


-- stylua: ignore start
vim.api.nvim_set_hl(0, 'TinyInlineDiagnosticVirtualTextHint', { bg = 'none', fg = colors.get_color('TinyInlineDiagnosticVirtualTextHint', 'fg') })
vim.api.nvim_set_hl(0, 'TinyInlineDiagnosticVirtualTextInfo', { bg = 'none', fg = colors.get_color('TinyInlineDiagnosticVirtualTextInfo', 'fg') })
vim.api.nvim_set_hl(0, 'TinyInlineDiagnosticVirtualTextWarn', { bg = 'none', fg = colors.get_color('TinyInlineDiagnosticVirtualTextWarn', 'fg') })
vim.api.nvim_set_hl(0, 'BlinkCmpMenu', { bg = 'none', fg = colors.get_color('BlinkCmpMenu', 'fg') })

vim.api.nvim_set_hl(0, 'DiagnosticSignWarn', { bg = 'none', fg = colors.get_color('DiagnosticSignWarn', 'fg') })
vim.api.nvim_set_hl(0, 'DiagnosticSignHint', { bg = 'none', fg = colors.get_color('DiagnosticSignHint', 'fg') })
vim.api.nvim_set_hl(0, 'DiagnosticSignInfo', { bg = 'none', fg = colors.get_color('DiagnosticSignInfo', 'fg') })
vim.api.nvim_set_hl(0, 'DiagnosticSignError', { bg = 'none', fg = colors.get_color('DiagnosticSignError', 'fg') })
vim.api.nvim_set_hl(0, 'DiagnosticSignOk', { bg = 'none', fg = colors.get_color('DiagnosticSignOk', 'fg') })

vim.api.nvim_set_hl(0, 'TroubleNormal', { bg = 'none', fg = colors.get_color('TroubleNormal', 'fg') })
vim.api.nvim_set_hl(0, 'TroubleCount', { bg = 'none', fg = colors.get_color('TroubleCount', 'fg') })

vim.api.nvim_set_hl(0, 'FloatShadow', { bg = 'none', fg = colors.get_color('FloatShadow', 'fg') })
vim.api.nvim_set_hl(0, 'FloatShadowThrough', { bg = 'none', fg = colors.get_color('FloatShadowThrough', 'fg') })
