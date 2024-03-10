---@class functions.toggle
local M = {}

local enabled = true
function M.diagnostics()
  -- if this Neovim version supports checking if diagnostics are enabled
  -- then use that for the current state
  if vim.diagnostic.is_disabled then
    enabled = not vim.diagnostic.is_disabled()
  end
  enabled = not enabled

  if enabled then
    vim.diagnostic.enable()
    print 'Enabled diagnostics'
  else
    vim.diagnostic.disable()
    print 'Disabled diagnostics'
  end
end

---@param opts { option: string, silent: boolean, values: table }
function M.option(opts)
  local option = opts.option
  local silent = opts.silent
  local values = opts.values

  if values then
    if vim.opt_local[option]:get() == values[1] then
      ---@diagnostic disable-next-line: no-unknown
      vim.opt_local[option] = values[2]
    else
      ---@diagnostic disable-next-line: no-unknown
      vim.opt_local[option] = values[1]
    end
    return print('Set ' .. option .. ' to ' .. vim.opt_local[option]:get())
  end
  ---@diagnostic disable-next-line: no-unknown
  vim.opt_local[option] = not vim.opt_local[option]:get()
  if not silent then
    if vim.opt_local[option]:get() then
      print('Enabled ' .. option)
    else
      print('Disabled ' .. option)
    end
  end
end

function M.format()
  vim.g.autoformat = not vim.g.autoformat
  print('Autoformat: ' .. tostring(vim.g.autoformat))
end

return M
