local M = {}

M.google_search = function()
  local query = require("lib.visual").get_selection()
  local url = "https://www.google.com/search?q="
  vim.ui.open(url .. query)
end

return M
