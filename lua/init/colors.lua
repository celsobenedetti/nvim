local colors_path = vim.fn.expand('~/.local/state/omarchy/current/theme/colors.toml')

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

colors.bg = colors.background
colors.fg = colors.foreground
colors.secondary = colors.selection

state.colors = colors
