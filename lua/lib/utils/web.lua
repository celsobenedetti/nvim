local M = {}

M.google_search = function()
  local query = C.utils.get_visual_selection()
  vim.ui.open(C.url.google_search .. query)
end

---@param issue string
M.open_issue = function(issue)
  local is_linear = issue.match(issue, '^C-') ~= nil
  -- local url = is_linear and C.url.linear_issue or C.url.jira_issue
  local url = C.url.jira_issue
  vim.ui.open(url .. issue)
end

M.open_selected_issue = function()
  local issue = C.utils.get_visual_selection()

  -- If there is no visual selection
  if issue == nil then
    vim.api.nvim_feedkeys(Keys 'yiW', 'n', true)
    os.execute('sleep ' .. tonumber(0.5)) -- HACK: 😭
    issue = vim.fn.getreg '+'
  end

  M.open_issue(issue)
end

return M
