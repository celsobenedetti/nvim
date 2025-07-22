local M = {}

-- Helper function to convert hex to RGB
local function hex_to_rgb(hex_color)
  hex_color = hex_color:gsub("#", "") -- Remove '#' if present
  local r = tonumber(hex_color:sub(1, 2), 16)
  local g = tonumber(hex_color:sub(3, 4), 16)
  local b = tonumber(hex_color:sub(5, 6), 16)
  return r, g, b
end

-- Helper function to convert RGB to hex
local function rgb_to_hex(r, g, b)
  return string.format("#%02X%02X%02X", r, g, b)
end

-- lighten a hex color by a given amount
local function lighten(hex_color, amount)
  -- Convert hex color to RGB
  local r, g, b = hex_to_rgb(hex_color)

  -- Lighten each color channel
  r = math.min(255, r + amount)
  g = math.min(255, g + amount)
  b = math.min(255, b + amount)

  -- Convert back to hex
  return rgb_to_hex(r, g, b)
end

local function darken(hex_color, amount)
  -- Convert hex color to RGB
  local r, g, b = hex_to_rgb(hex_color)

  -- 256 is 100%
  -- amount is the percentage of 256 to decrease by, so if 10% decrease, amount = 0.1
  amount = math.floor(amount * 256)

  -- Darken each color channel
  r = math.max(0, r - amount)
  g = math.max(0, g - amount)
  b = math.max(0, b - amount)

  -- Convert back to hex
  return rgb_to_hex(r, g, b)
end

M.lighten = lighten
M.darken = darken
M.hex_to_rgb = hex_to_rgb
M.rgb_to_hex = rgb_to_hex

return M
