local state = require('state')

local colors_path = vim.fn.expand('~/.config/omarchy/current/theme/colors.toml')
local colors = {}

local file = io.open(colors_path, 'r')
if file then
  for line in file:lines() do
    local key, value = line:match('^([%w_]+)%s*=%s*"(.*)"')
    if key and value then
      colors[key] = value
    end
  end
  file:close()
end

colors.bg = colors.background or colors.color0
colors.fg = colors.foreground or colors.color7
colors.secondary = colors.color7

state.colors = colors
