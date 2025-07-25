local M = {}

--- grabs the current visual selection and opens it in a search engine
--- defaults to google
M.enhanced_open = function()
  local s = require("lib.visual").get_selection()
  local ok, _ = pcall(require("lib.web").search, s or "")
  if ok then
    return
  end
end

return M
