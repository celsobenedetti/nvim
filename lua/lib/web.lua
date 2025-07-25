local strings = require("lib.strings")

-- module: web.lua
local M = {}

---@type table<string, string|function>
local search_engines = {
  g = "https://www.google.com/search?q=",
  y = "https://www.youtube.com/results?search_query=",
  gh = function(q)
    if q:find("/") then
      return "https://github.com/" .. q
    end

    return "https://github.com/search?q=" .. strings.urlencode(q) .. "&type=repositories"
  end,
}

---@type table<string, string|function>
local regex_redirects = {
  {
    -- github.com/owner/repo
    "^([a-zA-Z0-9_-]+)/([a-zA-Z0-9_-]+)$",
    function(s)
      return "https://github.com/" .. s
    end,
  },
  { "^lazyvim", "https://lazyvim.org" },
  { "^mt$", "https://monkeytype.com" },
}

---@param query string
---@return string
local redirect_from_regex = function(query)
  query = strings.trim(query)
  query = query:lower()
  for _, pair in ipairs(regex_redirects) do
    if query:find(pair[1]) then
      local redirect = pair[2]
      if type(redirect) == "string" then
        return redirect
      end
      return redirect(query)
    end
  end
  return ""
end

---@param query string
---@return string
local query_from_prefix = function(query)
  query = strings.trim(query)
  for prefix, engine in pairs(search_engines) do
    if prefix == query:sub(1, #prefix):lower() then
      query = query:sub(#prefix + 1)
      query = strings.trim(query)

      if type(engine) == "string" then
        return engine .. strings.urlencode(query)
      end

      return engine(strings.trim(query))
    end
  end
  return ""
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
  if not query or query == "" then
    return ""
  end

  return query
end

-- search gets the text from the current visual selection
-- the text is queried into a search engine
---@param s string
M.search = function(s)
  if s == "" then
    return
  end

  s = strings.trim(s)
  local query = M.get_search_url_from_query(s)
  if query == "" then
    query = (search_engines.g .. strings.urlencode(s))
  end
  vim.ui.open(query)
end

return M
