return function(prompt_bufnr)
  local actions = require 'telescope.actions'
  local action_state = require 'telescope.actions.state'
  local path = action_state.get_selected_entry(prompt_bufnr).path
  local root = vim.fs.root(0, '.git') or ''
  if #root > 1 then
    path = path:gsub(root .. '/', '')
  end
  actions.close(prompt_bufnr)
  vim.api.nvim_put({ path }, 'c', false, true)
  -- require('batatao' .. path)
end
