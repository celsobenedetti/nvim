-- module: strings.lua
---@class LibStrings
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

M.shellescape = function(s)
  s = s:gsub(' ', '\\ ')

  if s:sub(-1) == '/' then
    s = s:sub(1, -2)
  end

  return s
end

---Split an ex-command arg string into whitespace-separated tokens, honoring
---"..." and '...' quoting and backslash escapes (space, quote, backslash).
---Any other `\X` is kept verbatim so rg patterns like `\bword\b` survive;
---a shell-style "escape any char" would strip their backslashes.
---@param args string
---@return string[]
M.split_args = function(args)
  local result, current, in_arg, quote = {}, '', false, nil
  local i, n = 1, #args
  while i <= n do
    local c = args:sub(i, i)
    if c == '\\' then
      local nxt = args:sub(i + 1, i + 1)
      if nxt ~= '' and (nxt == ' ' or nxt == '"' or nxt == "'" or nxt == '\\') then
        current = current .. nxt
        i = i + 2
      else
        current = current .. c
        i = i + 1
      end
      in_arg = true
    elseif quote then
      if c == quote then
        quote = nil
      else
        current = current .. c
      end
      i = i + 1
    elseif c == '"' or c == "'" then
      quote = c
      in_arg = true
      i = i + 1
    elseif c == ' ' or c == '\t' then
      if in_arg then
        result[#result + 1] = current
        current, in_arg = '', false
      end
      i = i + 1
    else
      current = current .. c
      in_arg = true
      i = i + 1
    end
  end
  if in_arg then
    result[#result + 1] = current
  end
  return result
end

--- highlight text with a given highlight group
--- @param hl string the highlight group to set
--- @param text string the text to highlight
M.hl = function(hl, text)
  return '%#' .. hl .. '#' .. text .. '%*'
end

--- Returns text wrapped in statusline highlight markup, foregrounded with the
--- given hex color. Registers (and reuses) a global highlight group derived
--- from the hex, since %#..# markup only accepts named groups.
--- @param text string the text to highlight
--- @param hex string? the hex color; without one, text is returned as-is
--- @return string
M.colored = function(text, hex)
  if not hex then
    return text
  end

  local group = 'Hex' .. hex:gsub('#', '')
  vim.api.nvim_set_hl(0, group, { fg = hex })
  return M.hl(group, text)
end

M.split = function(s, sep)
  local fields = {}
  string.gsub(s, string.format('([^%s]+)', sep), function(c)
    table.insert(fields, c)
  end)
  return fields
end

return M
