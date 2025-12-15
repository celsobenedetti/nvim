local strings = require('lib.strings')

---@type table<string, string|function>
local regex_redirects = {
  {
    -- github: owner/repo
    '^[a-zA-Z0-9_-]+/[a-zA-Z0-9_.-]+$',
    function(s)
      return 'https://github.com/' .. s
    end,
  },
  {
    -- github: github.com/owner/repo
    '^github.com/[a-zA-Z0-9_-]+/[a-zA-Z0-9_.-]+$',
    function(s)
      return 'https://' .. s
    end,
  },
  { '^lazyvim', 'https://lazyvim.org' },
  { '^mt$', 'https://monkeytype.com' },
  -- TODO: support table of strings so can reuse same function with different patterns
  {
    '^%s*VA-[0-9]*',
    function(s)
      return vim.g.web.jira .. s
    end,
  },

  {
    '^%s*va-[0-9]*',
    function(s)
      return vim.g.web.jira .. s
    end,
  },
  {
    '^INT-[0-9]*',
    function(s)
      return vim.g.web.jira .. s
    end,
  },
}

---@param query string
---@return string
local redirect_from_regex = function(query)
  query = strings.trim(query)
  for _, pair in ipairs(regex_redirects) do
    if query:find(pair[1]) then
      local redirect = pair[2]
      if type(redirect) == 'string' then
        return redirect
      end
      return redirect(query)
    end
  end
  return ''
end

local M = {}
M.normal = function()
  local line = vim.fn.getline('.')

  if not line:find('https') then
    Snacks.notify('no link found in line')
    return
  end

  ---@type string
  local url = line:match('https?://[-A-Za-z0-9+&@#/%?=~_|!:,.;]*[-A-Za-z0-9+&@#/%=~_|]')
  if not url or #url == 0 then
    Snacks.notify('no url found in line')
    return
  end

  if url:find('youtube.com') or url:find('youtu.be') then
    vim.cmd('!omarchy-launch-or-focus-webapp youtube-from-nvim ' .. url)
    return
  end

  vim.cmd('!xdg-open ' .. url)
end

M.visual = function()
  local s = require('lib.visual').get_selection()
  if s == '' or s == nil then
    return
  end
  s = strings.trim(s)

  local redirect = redirect_from_regex(s)
  if #redirect > 0 then
    vim.ui.open(redirect)
  end
end

return M
