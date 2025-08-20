---@module run_tasks
local M = {}

local overseer = require 'overseer'

--- @class task
--- @field name string
--- @field cmd string
--- @field args string[]
--- @field cwd? string

--- run tasks
---@param tasks task[]
M.run = function(tasks)
  for _, task in ipairs(tasks) do
    local template = { cmd = task.cmd, args = task.args, name = task.name }

    if task.cwd then
      template.cwd = task.cwd
    end

    overseer.register_template {
      name = task.name,
      builder = function()
        return template
      end,
    }
  end

  for _, task in ipairs(tasks) do
    overseer.run_template { name = task.name }
  end
end

--- run tasks and fullscreen overseer
---@param tasks task[]
M.startup = function(tasks)
  M.run(tasks)

  vim.defer_fn(function()
    vim.cmd 'OverseerToggle'
    vim.defer_fn(function()
      vim.cmd 'wincmd k'
      vim.cmd 'wincmd q'
    end, 50)
  end, 50)
end

return M
