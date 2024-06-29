local get_visual_selection = require 'c.functions.utils.get_visual_selection'

local jira = 'https://ocelotbot.atlassian.net/browse/'
local linear = 'https://linear.app/celsobenedetti/issue/'

local M = {}

---@param issue string
M.open_issue = function(issue)
  local is_linear = issue.match(issue, 'DEV') ~= nil
  local url = is_linear and linear or jira
  vim.ui.open(url .. issue)
end

M.open_selected_issue = function()
  local issue = get_visual_selection()

  -- If there is no visual selection
  if issue == nil then
    vim.api.nvim_feedkeys(Keys 'yiW', 'n', true)
    os.execute('sleep ' .. tonumber(0.5))
    issue = vim.fn.getreg '+'
  end

  M.open_issue(issue)
end

return M
