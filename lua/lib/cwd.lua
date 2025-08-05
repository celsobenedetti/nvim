local M = {}

M.is_llm_chats = function()
  local path = vim.fn.expand '%:p'
  return path:find '.local/chats'
end

---@return string
M.cwd = function()
  return vim.fs.root(0, '.git') or vim.uv.cwd() --[[@as string]]
end

---@param strings table<string>
---@return boolean
M.includes = function(strings)
  local cwd = M.cwd()
  for _, s in ipairs(strings) do
    if cwd:find(s) then
      return true
    end
  end
  return false
end

local fd = '!fd . --type=directory --hidden -E .hugo/ -E .git/ -E .pnpm/ -E .obsidian '
M.directories = function()
  local cwd = M.cwd()
  local fd_result = vim.api.nvim_exec2(fd .. cwd, { output = true })

  local dirs = vim.split(fd_result.output, '\n')
  dirs = vim.tbl_filter(function(item)
    return item ~= '' and not string.match(item, '--type=directory')
  end, dirs)

  return dirs
end

return M
