local strings = require 'lib.strings'

-- module: web.lua
local M = {}

---@param s string
---@return boolean
M.does_string_match_url_without_protocol = function(s)
  if s:find '^[a-z]+://' then
    return false
  end
  -- match 'label.label' or more with each label 1+ chars, only alphanum/dash, no leading/trailing dash
  local labels = {}
  for label in s:gmatch '([^.]+)' do
    table.insert(labels, label)
  end
  if #labels < 2 then
    return false
  end
  local tld = labels[#labels]
  if not tld:match '^[a-zA-Z][a-zA-Z]+$' then
    return false
  end
  for i = 1, #labels - 1 do
    local label = labels[i]
    if not label:match '^[a-zA-Z0-9][a-zA-Z0-9%-]*[a-zA-Z0-9]$' and not label:match '^[a-zA-Z0-9]$' then
      return false
    end
    if label:find '%-%-' then
      return false
    end
  end
  return true
end

---@type table<string, string|function>
local search_engines = {
  ['g '] = 'https://www.google.com/search?q=',
  y = 'https://www.youtube.com/results?search_query=',
  gh = function(q)
    if q:find '/' then
      return 'https://github.com/' .. q
    end

    return 'https://github.com/search?q=' .. strings.urlencode(q) .. '&type=repositories'
  end,
}

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
    'VA-[0-9]*',
    function(s)
      return vim.g.web.jira .. s
    end,
  },
  {
    'va-[0-9]*',
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

---@param query string
---@return string
local query_from_prefix = function(query)
  query = strings.trim(query)
  local prefixes = {}
  for p in pairs(search_engines) do
    table.insert(prefixes, p)
  end
  table.sort(prefixes, function(a, b)
    return #a > #b
  end)
  for _, prefix in ipairs(prefixes) do
    local engine = search_engines[prefix]
    if prefix == query:sub(1, #prefix):lower() then
      query = query:sub(#prefix + 1)
      query = strings.trim(query)

      if type(engine) == 'string' then
        return engine .. strings.urlencode(query)
      end

      return engine(strings.trim(query))
    end
  end
  return ''
end

-- google.com is the default engine
-- Let's support special handlers inside this function
-- type 1: prefix to specify different search engines
-- type 2: match regex to open specific urls
--
-- type 1: prefix
-- if text starts with "gh" then search on github
-- https://github.com/search?q=%s&type=repositories
--
-- type 1: prefix
-- if text starts with "y" then search on youtube
-- https://www.youtube.com/results?search_query=%s
--
-- type 2: regex
-- if text contains "lazyvim" then simply open lazyvim.org
--
-- type 2: regex
-- if text contains "mt" then simply open monkeytype.com
---@param s string
---@return string
M.get_search_url_from_query = function(s)
  s = strings.trim(s)

  local redirect = redirect_from_regex(s)
  if #redirect > 0 then
    return redirect
  end

  local query = query_from_prefix(s)
  if query and #query > 0 then
    return query
  end

  if M.does_string_match_url_without_protocol(s) then
    return 'https://' .. s
  end

  return ''
end

-- search gets the text from the current visual selection
-- the text is queried into a search engine
---@param s string
M.search = function(s)
  if s == '' then
    return
  end

  s = strings.trim(s)
  local query = M.get_search_url_from_query(s)

  if query == '' then
    query = (search_engines.g .. strings.urlencode(s))
  end
  vim.ui.open(query)
end

return M
