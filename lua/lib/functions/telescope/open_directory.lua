local M = {}

local pickers = require 'telescope.pickers'
local finders = require 'telescope.finders'
local conf = require('telescope.config').values
local actions = require 'telescope.actions'
local action_state = require 'telescope.actions.state'

M.run = function(opts)
  local dirs = require('lib.utils.find_directories').find_directories()

  pickers
    .new({}, {
      prompt_title = 'Open directory',
      finder = finders.new_table {
        results = dirs,
      },
      sorter = conf.generic_sorter(opts),
      attach_mappings = function(prompt_bufnr, _)
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
          local selection = action_state.get_selected_entry()

          local destination = selection[1]
          if not destination then
            return
          end

          vim.cmd('Neotree dir=' .. destination)
        end)
        return true
      end,
    })
    :find()
end

return M
