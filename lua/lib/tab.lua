--- Tab helpers, backed by tabby.nvim when available.
---@class LibTab
local M = {}

local pending_name = nil

local function tabby()
  local ok, mod = pcall(require, 'tabby')
  return ok and mod or nil
end

local function tab_name()
  local ok, mod = pcall(require, 'tabby.feature.tab_name')
  return ok and mod or nil
end

---Whether tabby.nvim (needed to read/rename tabs) is available.
---@return boolean
M.available = function()
  return tabby() ~= nil
end

---Rename a tab. If `name` is nil/empty, prompts via `vim.ui.input`.
---@param name? string
---@param tabid? number tab id, defaults to the current tab
M.rename = function(name, tabid)
  local tn = tab_name()
  if not tn then
    Snacks.notify.warn("can't rename tab: tabby.nvim not installed")
    return
  end
  if name and #name > 0 then
    tn.set(tabid or 0, name)
    return
  end
  vim.ui.input({ prompt = 'rename Tab: ' }, function(input)
    if not input or #input == 0 then
      return
    end
    tn.set(tabid or 0, input)
  end)
end

---Derive a git/codediff tab name from a command string, e.g. `tab Git show
---abc123` -> ` git show abc123`, `CodeDiff main HEAD` -> ` diff main HEAD`.
---@param last string
---@return string? nil when the command is not a Git/CodeDiff command
M.name_from_command = function(last)
  if last == '' then
    return nil
  end
  local git_args = last:match('^:?%s*tab%s+Git%s+(.*)$') or last:match('^:?%s*Git%s+(.*)$')
  if git_args and git_args ~= '' then
    return vim.g.icons.git.git .. 'git ' .. vim.trim(git_args)
  end
  local cdiff_args = last:match('^:?%s*CodeDiff%s+(.*)$')
  if cdiff_args and cdiff_args ~= '' then
    return vim.g.icons.git.diff .. 'diff ' .. vim.trim(cdiff_args)
  end
  return nil
end

---Get the name of a tab.
---@param tabid? number tab id, defaults to the current tab
---@return string? nil when tabby is not available
M.get_name = function(tabid)
  local tn = tab_name()
  if not tn then
    return nil
  end
  return tn.get(tabid or 0)
end

---Find the first tab whose name matches a plain string.
---@param pattern string literal substring to match
---@return number? tabid, or nil when not found (or tabby unavailable)
M.find = function(pattern)
  local tn = tab_name()
  if not tn then
    return nil
  end
  for _, tabid in ipairs(vim.api.nvim_list_tabpages()) do
    local name = tn.get(tabid)
    if name and name:find(pattern, 1, true) then
      return tabid
    end
  end
  return nil
end

---Queue a tab name to be applied by the next tab that opens (e.g. CodeDiff
---opens asynchronously); consumed via `M.consume_next_name`.
---@param name string
M.set_next_name = function(name)
  pending_name = name
end

---Read and clear the queued tab name.
---@return string?
M.consume_next_name = function()
  local name = pending_name
  pending_name = nil
  return name
end

return M
