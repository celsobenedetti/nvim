local cwd = require 'lib.cwd'

local M = {}

M.mv_file = function()
  --- @type snacks.picker.finder.Item[]
  local snack_items = {}
  for _, dir in ipairs(cwd.directories()) do
    table.insert(snack_items, {
      text = dir,
      file = dir,
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
      vim.cmd('silent! !mv % ' .. destination)
      vim.cmd('e ' .. destination .. '/' .. vim.fn.expand '%:t')
      vim.api.nvim_buf_delete(original_buffer, { force = true })
    end,
  }
end

return M
