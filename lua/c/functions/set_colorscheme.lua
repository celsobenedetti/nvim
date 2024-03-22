local M = {}

local dawn = 6
local dusk = 15

--- Sets the colorscheme, and background light/dark based on time of day.
---@param colorscheme string
M.run = function(colorscheme)
  vim.cmd.colorscheme(colorscheme)

  local hour = tonumber(os.date '%H')
  if hour >= dawn and hour < dusk then
    vim.opt.background = 'light'
  else
    vim.opt.background = 'dark'
  end
end

return M
