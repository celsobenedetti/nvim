local get_visual_selection = require 'c.functions.utils.get_visual_selection'

local M = {}

local URL = 'https://www.google.com/search?q='

M.google_search = function()
  local query = get_visual_selection()
  vim.ui.open(URL .. query)
end

return M
