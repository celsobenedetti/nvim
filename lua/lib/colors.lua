local M = {}

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

return M
