local M = {}

function M.setup(opts)
  M.opts = opts or {}
end

local function request(method, url, data, callback)
  -- TODO: implement request
end

---@param issue_key string
---@param comment string
---@param callback function
function M.add_comment(issue_key, comment, callback)
  local url = '/rest/api/3/issue/' .. issue_key .. '/comment'
  local data = {
    body = {
      type = 'doc',
      version = 1,
      content = {
        {
          type = 'paragraph',
          content = {
            {
              type = 'text',
              text = comment,
            },
          },
        },
      },
    },
  }
  request('POST', url, data, callback)
end

---@param issue_key string
---@param callback function
function M.get_transitions(issue_key, callback)
  local url = '/rest/api/3/issue/' .. issue_key .. '/transitions'
  request('GET', url, nil, callback)
end

---@param issue_key string
---@param target_status string
---@param callback function
function M.change_issue_status(issue_key, target_status, callback)
  M.get_transitions(issue_key, function(err, result)
    if err then
      callback(err, nil)
      return
    end
    local transition_id
    if result and result.transitions then
      for _, transition in ipairs(result.transitions) do
        if transition.name == target_status then
          transition_id = transition.id
          break
        end
      end
    end

    if not transition_id then
      callback('Transition to "' .. target_status .. '" not found for issue ' .. issue_key, nil)
      return
    end

    local url = '/rest/api/3/issue/' .. issue_key .. '/transitions'
    local data = {
      transition = {
        id = transition_id,
      },
    }
    request('POST', url, data, callback)
  end)
end

---@param issue_key string
---@param time_spent string
---@param callback function
function M.log_work(issue_key, time_spent, callback)
  local url = '/rest/api/3/issue/' .. issue_key .. '/worklog'
  local data = {
    timeSpent = time_spent,
  }
  request('POST', url, data, callback)
end

return M
