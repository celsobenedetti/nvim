local M = {}

--- runs first set of keys immediately
--- runs second set of keys after delay
---@param key1 string
---@param key2 string
---@param delay number | nil

M.with_delay = function(key1, key2, delay)
  return function()
    if not vim.g.snacks_animate then
      vim.api.nvim_feedkeys(Keys(key1), 'n', true)
      vim.cmd('normal! ' .. key2)
      return
    end

    vim.api.nvim_feedkeys(Keys(key1), 'n', true)
    vim.defer_fn(function()
      vim.cmd('normal! ' .. key2)
    end, vim.g.delay or 100)
  end
end

M.G = function()
  local count = vim.v.count or 1
  if count > 1 then
    vim.cmd(':' .. count)
    return
  end

  local feed_keys = M.with_delay('G', 'zz', vim.g.delay)
  feed_keys()
end

return M
