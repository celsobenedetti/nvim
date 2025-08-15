local M = {}

--- returns true if any dirs in cwd match the path
---@param paths string[]
---@return boolean
M.is_path = function(paths)
  local file_dir = vim.fn.expand '%:p'
  for _, path in ipairs(paths) do
    if file_dir:find(path) then
      return true
    end
  end

  return false
end

---@return string
M.cwd = function()
  return vim.fs.root(0, '.git') or vim.uv.cwd() --[[@as string]]
end

--- returns true if the file is found in cwd
---@param file string
---@return string?
M.find_file = function(file)
  return vim.fs.root(0, file)
end

--- @return string[]
M.directories = function()
  local fd = '!fd . --type=directory'
  local fd_result = vim.api.nvim_exec2(fd, { output = true })

  local dirs = vim.split(fd_result.output, '\n')
  dirs = vim.tbl_filter(function(item)
    return item ~= '' and not string.match(item, '--type=directory')
  end, dirs)

  return dirs
end

return M
