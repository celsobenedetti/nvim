---@module run_tasks
local M = {}

local overseer = require 'overseer'

--- run tasks
---@param tasks overseer.TaskDefinition[]
M.run = function(tasks)
  for _, task in ipairs(tasks) do
    overseer.register_template {
      name = task.name,
      builder = function()
        return task
      end,
    }
  end

  for _, task in ipairs(tasks) do
    overseer.run_task { name = task.name, autostart = true }
  end
end

--- run tasks and fullscreen overseer
---@param tasks overseer.TaskDefinition[]
M.startup = function(tasks)
  M.run(tasks)

  vim.schedule(function()
    vim.cmd 'OverseerToggle'
    vim.schedule(function()
      vim.cmd 'wincmd k'
      vim.cmd 'wincmd q'
    end)
  end)
end

return M
