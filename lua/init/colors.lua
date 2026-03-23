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

colors.lightgray = colors.foreground or colors.color7
colors.darkgray = colors.background or colors.color0
colors.gray = colors.foreground or colors.color7
colors.white = colors.foreground or colors.color7
colors.black = colors.background or colors.color0
colors.bg = colors.background or colors.color0

vim.g.colors = colors
