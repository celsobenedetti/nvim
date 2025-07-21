local M = {}

local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

M.mv_file = function(opts)
  local cwd = require("lib.cwd")

  pickers
    .new({}, {
      prompt_title = "Move file to directory",
      finder = finders.new_table({
        results = cwd.directories(),
      }),
      sorter = conf.generic_sorter(opts),
      attach_mappings = function(prompt_bufnr, _)
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
          local selection = action_state.get_selected_entry()

          local destination = selection[1]
          if not destination then
            return
          end

          local original_buffer = vim.api.nvim_get_current_buf()
          vim.cmd("silent! !mv % " .. destination)
          vim.cmd("e " .. destination .. "/" .. vim.fn.expand("%:t"))
          vim.api.nvim_buf_delete(original_buffer, { force = true })
        end)
        return true
      end,
    })
    :find()
end

return M
