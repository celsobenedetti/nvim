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

---Rename the current tab. If `name` is nil/empty, prompts via `vim.ui.input`.
---@param name? string
M.rename = function(name)
  local tabby = tabby()
  if not tabby then
    Snacks.notify.warn("can't rename tab: tabby.nvim not installed")
    return
  end
  if name and #name > 0 then
    tabby.tab_rename(name)
    return
  end
  vim.ui.input({ prompt = 'rename Tab: ' }, function(input)
    if not input or #input == 0 then
      return
    end
    tabby.tab_rename(input)
  end)
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
