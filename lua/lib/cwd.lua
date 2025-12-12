local M = {}
local home = os.getenv('HOME') or '/home/celso'

--- returns true if cwd matches any of the paths
---@param paths string[]
---@return boolean
M.matches = function(paths)
  local file_dir = vim.fn.expand('%:p')
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

M.root = M.cwd

M.current_file = function()
  local cwd = M.cwd()
  local file = vim.fn.expand('%')
  file = file:gsub(cwd .. '/', '')
  file = file:gsub(home, '~')
  return file:gsub('%./', '')
end

--- returns true if the file is found in cwd
---@param file string
---@return string?
M.find_file = function(file)
  return vim.fs.root(0, file)
end

--- get all directories in cwd
--- @param opts {git:boolean}
--- @return string[]
M.directories = function(opts)
  opts = opts or {}
  local dir = ''
  if opts.git then
    dir = vim.fs.root(0, '.git') or '.'
  end
  local fd = string.format('!fd . %s --type=directory ', dir)
  local fd_result = vim.api.nvim_exec2(fd, { output = true })

  local dirs = vim.split(fd_result.output, '\n')
  dirs = vim.tbl_filter(function(item)
    return item ~= '' and not string.match(item, '--type=directory')
  end, dirs)

  return dirs
end

return M
