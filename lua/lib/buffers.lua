---@class LibBuffers
local M = {}

M.get_valid_bufs = function()
  local bufs = vim.api.nvim_list_bufs()
  local valid_bufs = {}
  for _, buf in ipairs(bufs) do
    if
      vim.api.nvim_get_option_value('buftype', { buf = buf }) ~= 'nofile'
      -- and vim.api.nvim_get_option_value('buftype', { buf = buf }) ~= 'terminal'
    then
      table.insert(valid_bufs, buf)
    end
  end
  return valid_bufs
end

M.is_file = function()
  return vim.bo.buftype ~= 'nofile' and vim.bo.buftype ~= 'nowrite'
end

---Write all valid buffers and quit, gracefully ignoring buffers that
---cannot be written (unnamed, special buftypes, unmodifiable, unmodified).
---Aborts the quit and reports if a genuine write fails.
M.wqa = function()
  local errors = {}
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_buf_is_loaded(buf) then
      local name = vim.api.nvim_buf_get_name(buf)
      if
        name ~= ''
        and vim.api.nvim_get_option_value('buftype', { buf = buf }) == ''
        and vim.api.nvim_get_option_value('modifiable', { buf = buf })
        and vim.api.nvim_get_option_value('modified', { buf = buf })
      then
        local ok, err = pcall(vim.api.nvim_buf_call, buf, function()
          vim.cmd.write()
        end)
        if not ok then
          local first_line = tostring(err):match('[^\n]+') or tostring(err)
          local msg = first_line:match('Vim%(.-%):%s*(.+)') or first_line
          errors[#errors + 1] = string.format('%s: %s', name, msg)
        end
      end
    end
  end
  if #errors > 0 then
    vim.notify(table.concat(errors, '\n'), vim.log.levels.ERROR, { title = 'wqa' })
    return
  end
  vim.cmd('qa!')
end

return M
