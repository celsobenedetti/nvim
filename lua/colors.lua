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

return M
