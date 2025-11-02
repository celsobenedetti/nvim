local M = {}

--- grabs the current visual selection and opens it in a search engine
--- defaults to google
M.omni_open = function()
  local s = require('lib.visual').get_selection()
  local ok, _ = pcall(require('lib.web').search, s or '')
  if ok then
    return
  end
end

M.gx = function()
  local line = vim.fn.getline '.'

  if not line:find 'https' then
    Snacks.notify 'no link found in line'
    return
  end

  ---@type string
  local url = line:match 'https?://[-A-Za-z0-9+&@#/%?=~_|!:,.;]*[-A-Za-z0-9+&@#/%=~_|]'
  if not url or #url == 0 then
    Snacks.notify 'no url found in line'
    return
  end

  if url:find 'youtube.com' or url:find 'youtu.be' then
    vim.cmd('!omarchy-launch-or-focus-webapp youtube-from-nvim ' .. url)
    return
  end

  vim.cmd('!xdg-open ' .. url)
end

return M
