-- module: strings.lua
local M = {}

-- remove leading and trailing whitespace
---@param s string
---@return string
M.trim = function(s)
  return (s:gsub('^%s*(.-)%s*$', '%1'))
end

M.collapse_whitespace = function(s)
  return (s:gsub('%s+', ' '))
end

M.slugify = function(text)
  local s = text:lower()
  s = M.collapse_whitespace(s)
  s = s:gsub('[^a-z0-9%-%.]+', '-')
  s = s:gsub('^-+', '') -- remove leading hyphens
  s = s:gsub('-+$', '') -- remove trailing hyphens
  return s
end

---@param s string
---@return string
M.urlencode = function(s)
  if s == nil then
    return ''
  end
  s = s:gsub('\n', ' ')

  local result = s:gsub('([^%w _%%%-%.~])', function(c)
    return string.format('%%%02X', string.byte(c))
  end):gsub(' ', '+')

  return result
end

return M
