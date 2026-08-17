---@class LibColors
local M = {}


local function hex_to_rgb(hex)
  if not hex then
    return 0, 0, 0
  end
  hex = hex:gsub('#', '')
  return tonumber(hex:sub(1, 2), 16), tonumber(hex:sub(3, 4), 16), tonumber(hex:sub(5, 6), 16)
end

local function rgb_to_hex(r, g, b)
  return string.format('#%02x%02x%02x', r, g, b)
end

local function clamp(n)
  return math.min(255, math.max(0, n))
end

--- darken an RGB color towards black
---@param hex string RGB hex string, e.g. '#rrggbb'
---@param amount number 0-1, how much to darken (0 = no change, 1 = black)
---@return string
M.darken = function(hex, amount)
  local r, g, b = hex_to_rgb(hex)
  return rgb_to_hex(
    clamp(math.floor(r * (1 - amount))),
    clamp(math.floor(g * (1 - amount))),
    clamp(math.floor(b * (1 - amount)))
  )
end

--- lighten an RGB color towards white
---@param hex string RGB hex string, e.g. '#rrggbb'
---@param amount number 0-1, how much to lighten (0 = no change, 1 = white)
---@return string
M.lighten = function(hex, amount)
  local r, g, b = hex_to_rgb(hex)
  return rgb_to_hex(
    clamp(math.floor(r + (255 - r) * amount)),
    clamp(math.floor(g + (255 - g) * amount)),
    clamp(math.floor(b + (255 - b) * amount))
  )
end

--- get value for attribute of highlight group
---
--- :h synIDattr
---@param hl_group string highlight group
---@param attr string highlight attribute
M.get_color = function(hl_group, attr)
  return vim.fn.synIDattr(vim.fn.synIDtrans(vim.fn.hlID(hl_group)), attr)
end

--- get current omarchy colorscheme omarchy
---@return { colorscheme: string, colorscheme_plugin: table }
M.omarchy_colorscheme = function()
  local themes = require('plugins.theme')

  local colorscheme = themes[2].opts.colorscheme
  local colorscheme_plugin = themes[1]

  return {
    colorscheme = colorscheme or 'default',
    colorscheme_plugin = colorscheme_plugin or {},
  }
end

--- updates state.colors
---@param new_colors k,v table for state.colors
M.update = function(new_colors)
  local colors = state.colors
  for k, v in pairs(new_colors) do
    colors[k] = v
  end
  state.colors = colors
end

return M
