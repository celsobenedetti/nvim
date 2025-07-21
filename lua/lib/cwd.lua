local M = {}

M.is_llm_chats = function()
  local path = vim.fn.expand("%:p")
  return path:find(".local/chats")
end

local fd = "!fd . --type=directory --hidden -E .hugo/ -E .git/ -E .pnpm/ -E .obsidian "
M.directories = function()
  local cwd = vim.fs.root(0, ".git") or vim.uv.cwd() --[[@as string]]
  local fd_result = vim.api.nvim_exec2(fd .. cwd, { output = true })

  local dirs = vim.split(fd_result.output, "\n")
  dirs = vim.tbl_filter(function(item)
    return item ~= "" and not string.match(item, "--type=directory")
  end, dirs)

  return dirs
end

return M
