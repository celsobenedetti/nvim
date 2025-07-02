local M = {}

M.slugify = function(text)
  local s = text:lower() -- Convert to lowercase
  s = s:gsub('\\s+', ' ') -- collapse multiple spaces into one space
  s = s:gsub('[^a-z0-9%-%.]+', '-') -- Replace any character that's not a letter, number, hyphen, or period with a hyphen
  s = s:gsub('(^-+)|(-+$)', '') -- Remove leading and trailing hyphens
  return s
end

return M
