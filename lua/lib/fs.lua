local cwd = require 'lib.cwd'
local strings = require 'lib.strings'

local M = {}

M.mv_file = function()
  --- @type snacks.picker.finder.Item[]
  local snack_items = {}
  for _, dir in ipairs(cwd.directories { git = true }) do
    dir = dir .. '/' -- remove trailing slash
    table.insert(snack_items, {
      text = dir,
      file = dir,
      dir = dir,
      cmd = dir,
      desc = dir,
      preview = 'preview',
    })
  end

  Snacks.picker.pick {
    items = snack_items,
    confirm = function(picker, item)
      picker:close()

      local destination = item.text
      if not destination then
        return
      end

      local original_buffer = vim.api.nvim_get_current_buf()

      destination = strings.shellescape(destination)
      local current_file = strings.shellescape(vim.fn.expand '%')

      vim.cmd('silent! !mv ' .. current_file .. ' ' .. destination)
      local new_file = strings.shellescape((vim.fn.expand '%:t'))

      vim.cmd('e ' .. destination .. '/' .. new_file)
      vim.api.nvim_buf_delete(original_buffer, { force = true })
    end,
  }
end

M.rm = function()
  os.remove(vim.fn.expand '%')
  vim.api.nvim_feedkeys(Keys ':bdelete<cr>', 'n', true)
end

return M
