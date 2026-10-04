--- hunk (https://hunk.dev) diff viewer helpers.
---@class LibHunk
local M = {}

---Open `path` at `line` in the first tabpage.
---
---Called over RPC by scripts/hunk-editor/nvim, the $EDITOR of the hunk job in
---after/plugin/hunk.lua: hunk runs in its own tab, so its "edit this file"
---command has to land somewhere else -- the first tab, where the code lives.
---@param path string absolute path, as hunk resolves it
---@param line number 1-based line of the selected hunk
---@return string '' so `--remote-expr` prints nothing into hunk's terminal
function M.open(path, line)
  vim.api.nvim_set_current_tabpage(vim.api.nvim_list_tabpages()[1])
  vim.cmd.edit(vim.fn.fnameescape(path))
  -- the line can sit past the end of the buffer when the file changed since
  -- the diff was taken; landing on the file still beats refusing to open it.
  pcall(vim.api.nvim_win_set_cursor, 0, { line, 0 })
  return ''
end

return M
