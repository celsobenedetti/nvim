local M = {}

-- Returns true if the key adds additional space when surrounded
---@param char string
---@return boolean
M.adds_additional_space = function(char)
  local chars = { '(', ')', '{', '}', '[', ']' }
  for _, c in ipairs(chars) do
    if c == char then
      return true
    end
  end
  return false
end

--- Feeds keys to surround based on criteria
---@param char string the character to surround with
M.surround = function(char)
  if #char == 1 then
    vim.api.nvim_feedkeys(Keys 'S' .. char, 'v', true)
  else
    -- get first char
    char = char:sub(1, 1)
    vim.api.nvim_feedkeys(Keys 'S' .. char, 'v', true)
    vim.api.nvim_feedkeys(Keys 'ysi' .. char .. char, 'v', true)
  end

  if M.adds_additional_space(char) then
    vim.api.nvim_feedkeys(Keys 'lds ', 'v', true)
  end
end

--- Creates a visual mode keymap to surround selected text in some char
---@param keymaps string[] list of keys to trigger the surround
---@param surround_char string the character to surround with
M.surround_map = function(keymaps, surround_char)
  for _, key in ipairs(keymaps) do
    vim.keymap.set('v', key, function()
      M.surround(surround_char)
    end, { desc = 'Surround with ' .. surround_char })
  end
end

return M
