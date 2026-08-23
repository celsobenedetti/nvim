local colors_path = vim.fn.expand('~/.local/state/omarchy/current/theme/colors.toml')

--- @class DiffPalette
--- @field add string
--- @field add_fg string
--- @field delete string
--- @field add_char string
--- @field add_char_fg string
--- @field delete_char string
--- @field delete_char_fg string
--- @field lnum_fg string

--- @class OmarchyColors
--- @field color0 string
--- @field mode string
--- @field accent string
--- @field selection string
--- @field muted string
--- @field background string
--- @field dark_background string
--- @field darker_background string
--- @field lighter_background string
--- @field foreground string
--- @field dark_foreground string
--- @field light_foreground string
--- @field bright_foreground string
--- @field red string
--- @field green string
--- @field yellow string
--- @field blue string
--- @field magenta string
--- @field cyan string
--- @field bright_red string
--- @field bright_green string
--- @field bright_yellow string
--- @field bright_blue string
--- @field bright_magenta string
--- @field bright_cyan string
--- @field diff DiffPalette
local M = {}

local file = io.open(colors_path, 'r')
if file then
  for line in file:lines() do
    local key, value = line:match('^([%w_]+)%s*=%s*"(.*)"')
    if key and value then
      M[key] = value
    end
  end
  file:close()
end

M.bg = M.background
M.fg = M.foreground
M.secondary = M.selection

-- Consolidated diff color palette, taken from delta. Stored per-background
-- and exposed through a metatable so `colors.diff.<key>` resolves against
-- vim.o.background at access time: callers read flat palette keys and never
-- branch on background themselves.
local diff_palettes = {
  dark = {
    add = '#002800', -- delta plus-style
    delete = '#3F0001', -- delta minus-style
    add_fg = '#6fbf6f',
    -- Emph bg is bumped past delta's subtle default for visibility, and the
    -- emph fg colors the changed text itself (light green on dark).
    add_char = '#008000', -- plus-emph bg
    add_char_fg = '#B3F9C0', -- plus-emph fg
    delete_char = '#A01818', -- minus-emph bg
    delete_char_fg = '#FFC8C8', -- minus-emph fg
    lnum_fg = '#444444', -- delta line-numbers-style
  },
  light = {
    add = '#D0FFD0', -- delta plus-style
    add_fg = '#002800',
    delete = '#FFE0E0', -- delta minus-style
    add_char = '#7FE07F', -- plus-emph bg (darkened for light bg)
    add_char_fg = '#003800', -- plus-emph fg
    delete_char = '#FFA0A0', -- minus-emph bg
    delete_char_fg = '#5C0000', -- minus-emph fg
    lnum_fg = '#444444', -- delta line-numbers-style
  },
}

M.diff = setmetatable({}, {
  __index = function(_, key)
    local palette = diff_palettes[vim.o.background] or diff_palettes.dark
    return palette[key]
  end,
})

local themes = require('plugins.theme')

local colorscheme = themes[2].opts.colorscheme
local colorscheme_plugin = themes[1]

state.omarchy_colorscheme = {
  colorscheme = colorscheme or 'default',
  colorscheme_plugin = colorscheme_plugin or {},
}

vim.api.nvim_create_autocmd('User', {
  pattern = 'LazyDone',
  callback = function()
    if state.omarchy_colorscheme.colorscheme == 'default' then
      return
    end
    vim.api.nvim_set_hl(0, 'Bold', { fg = colors.fg, bold = true, cterm = { bold = true } })
    vim.api.nvim_set_hl(0, 'MsgArea', { link = config.hl.text_secondary }) -------- transparency changes -----------

    vim.api.nvim_set_hl(0, 'TextSecondary', { fg = colors.secondary or colors.fg })

    -- vim.api.nvim_set_hl( 0, 'TabLine', { bg = colors.get_color('StatusLine', 'bg'), fg = colors.get_color(config.hl.text.subtext, 'fg') })
    -- vim.api.nvim_set_hl(0, 'TabLineFill', { bg = colors.get_color('StatusLine', 'bg') })
    -- vim.api.nvim_set_hl(0, 'TabLineSel', { bg = colors.get_color('StatusLine', 'bg') , bold = true, underline=true})
    vim.api.nvim_set_hl(0, 'NonText', { link = 'Comment' })
    -- vim.api.nvim_set_hl(0, 'Folded', { bg = 'none' })
    vim.api.nvim_set_hl(0, 'FlashMatch', { link = 'MiniHipatternsNote' })
    vim.api.nvim_set_hl(0, 'BlinkCmpMenuBorder', { bg = 'none' })

    local hyperlink = { underline = true, fg = lib.colors.get_color('@markup.link.label.markdown_inline', 'fg') }
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

    vim.api.nvim_set_hl(0, 'CursorLineNr', { bg = 'none', fg = lib.colors.get_color('CursorLineNr', 'fg') })
    vim.api.nvim_set_hl(0, 'LineNr', { bg = 'none', fg = lib.colors.get_color('LineNr', 'fg') })
    vim.api.nvim_set_hl(0, 'GitSignsAdd', { bg = 'none', fg = lib.colors.get_color('GitSignsAdd', 'fg') })
    vim.api.nvim_set_hl(0, 'GitSignsChange', { bg = 'none', fg = lib.colors.get_color('GitSignsChange', 'fg') })
    vim.api.nvim_set_hl(0, 'GitSignsDelete', { bg = 'none', fg = lib.colors.get_color('GitSignsDelete', 'fg') })

    vim.api.nvim_set_hl(0, 'TroubleNormal', { bg = 'none', fg = lib.colors.get_color('TroubleNormal', 'fg') })
    vim.api.nvim_set_hl(0, 'PmenuSbar', { bg = 'none', fg = lib.colors.get_color('PmenuSbar', 'fg') })
    vim.api.nvim_set_hl(0, 'WinBarNC', { bg = 'none', fg = lib.colors.get_color('WinBarNC', 'fg') })
    vim.api.nvim_set_hl(0, 'WinBar', { bg = 'none', fg = lib.colors.get_color('WinBar', 'fg') })
    vim.api.nvim_set_hl(0, 'FloatTitle', { bg = 'none', fg = lib.colors.get_color('FloatTitle', 'fg') })
    vim.api.nvim_set_hl(0, 'SnacksBackdrop', { bg = 'none', fg = lib.colors.get_color('SnacksBackdrop', 'fg') })
    vim.api.nvim_set_hl(0, 'SnacksPickerNormal', { bg = 'none', fg = lib.colors.get_color('SnacksPickerNormal', 'fg') })

    vim.api.nvim_set_hl(
      0,
      'SnacksPickerCursorLine',
      { bg = 'none', fg = lib.colors.get_color('SnacksPickerCursorLine', 'fg') }
    )
    vim.api.nvim_set_hl(
      0,
      'SnacksPickerListCursorLine',
      { bg = 'none', fg = lib.colors.get_color('SnacksPickerListCursorLine', 'fg') }
    )
    vim.api.nvim_set_hl(0, 'SnacksPickerBorder', { bg = 'none', fg = lib.colors.get_color('SnacksPickerBorder', 'fg') })
    vim.api.nvim_set_hl(
      0,
      'SnacksPickerListBorder',
      { bg = 'none', fg = lib.colors.get_color('SnacksPickerListBorder', 'fg') }
    )
    vim.api.nvim_set_hl(
      0,
      'SnacksPickerListNormal',
      { bg = 'none', fg = lib.colors.get_color('SnacksPickerListNormal', 'fg') }
    )
    vim.api.nvim_set_hl(
      0,
      'SnacksPickerInputBorder',
      { bg = 'none', fg = lib.colors.get_color('SnacksPickerInputBorder', 'fg') }
    )
    vim.api.nvim_set_hl(
      0,
      'SnacksPickerInputNormal',
      { bg = 'none', fg = lib.colors.get_color('SnacksPickerInputNormal', 'fg') }
    )
    vim.api.nvim_set_hl(
      0,
      'SnacksPickerPreviewBorder',
      { bg = 'none', fg = lib.colors.get_color('SnacksPickerPreviewBorder', 'fg') }
    )
    vim.api.nvim_set_hl(
      0,
      'SnacksPickerPreviewNormal',
      { bg = 'none', fg = lib.colors.get_color('SnacksPickerPreviewNormal', 'fg') }
    )

    vim.api.nvim_set_hl(
      0,
      'SnacksPickerListCursorLine',
      { bg = 'none', fg = lib.colors.get_color('SnacksPickerListCursorLine', 'fg') }
    )
    vim.api.nvim_set_hl(
      0,
      'SnacksPickerPreviewCursorLine',
      { bg = 'none', fg = lib.colors.get_color('SnacksPickerPreviewCursorLine', 'fg') }
    )
    vim.api.nvim_set_hl(
      0,
      'SnacksPickerCursorLine',
      { bg = 'none', fg = lib.colors.get_color('SnacksPickerCursorLine', 'fg') }
    )
    vim.api.nvim_set_hl(0, 'SnacksPickerCode', { bg = 'none', fg = lib.colors.get_color('SnacksPickerCode', 'fg') })

    -- necessary since "laststatus=3", and "laststatus=0" render statuslien between panes
    -- vim.api.nvim_set_hl(0, 'StatusLine', { bg = 'none', fg = colors.get_color('StatusLine', 'fg') })
    vim.api.nvim_set_hl(0, 'WinSeparator', { bg = 'none', fg = lib.colors.get_color('WinSeparator', 'fg') })
    -- vim.api.nvim_set_hl(0, 'StatusLine', { link = 'WinSeparator' })
    vim.api.nvim_set_hl(0, 'StatusLineNC', { bg = 'none', fg = lib.colors.get_color('StatusLineNC', 'fg') })

    vim.api.nvim_set_hl(0, 'SatelliteBar', { bg = 'none', fg = lib.colors.get_color('SatelliteBar', 'fg') })
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
      { bg = 'none', fg = lib.colors.get_color('@markup.link.label.markdown_inline', 'fg'), italic = true }
    )

    if colors.folded then
      vim.api.nvim_set_hl(0, 'Folded', { bg = colors.folded })
    end
  end,
})

return M
