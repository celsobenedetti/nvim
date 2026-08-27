--- MRU back/forward buffer navigation.
---
--- Tracks buffer access order (like a browser history) with two stacks plus a
--- current-buffer pointer. `prev`/`next` *move* the current buffer between the
--- stacks, so the destination survives as the forward direction after going
--- back — unlike a single MRU list, which would erase it on visit.
---
--- `current` is updated synchronously inside `prev`/`next` before the caller
--- switches buffers, so the resulting `BufEnter` is a no-op (`record` guards on
--- `buf ~= current`) and never double-records.
---
--- Deleted/unloaded buffers are pruned on access: popping skips invalid
--- buffers until a valid one is found.
---
---@class LibBrowserHistory
local M = {}

M._back = {}
M._forward = {}
M._current = nil

local function is_valid(buf)
  return vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_buf_is_loaded(buf)
end

---Pop the first valid buffer off a stack, pruning invalid ones.
---@param stack number[]
---@return number? buf
local function pop_valid(stack)
  while #stack > 0 do
    local buf = table.remove(stack)
    if is_valid(buf) then
      return buf
    end
  end
  return nil
end

---Record that `buf` became current. No-op when it is already current (e.g. the
---re-entry that follows a `prev`/`next` jump).
---@param buf number
function M.record(buf)
  if M._current ~= nil and buf ~= M._current then
    M._back[#M._back + 1] = M._current
    M._forward = {}
    M._current = buf
  elseif M._current == nil then
    M._current = buf
  end
end

---Jump to the most recently accessed buffer before the current one.
---@return number? buf
function M.prev()
  local target = pop_valid(M._back)
  if not target then
    return nil
  end
  M._forward[#M._forward + 1] = M._current
  M._current = target
  return target
end

---Jump to the buffer most recently left via `prev`.
---@return number? buf
function M.next()
  local target = pop_valid(M._forward)
  if not target then
    return nil
  end
  M._back[#M._back + 1] = M._current
  M._current = target
  return target
end

---Clear all history. Used at plugin load and in tests.
function M.reset()
  M._back = {}
  M._forward = {}
  M._current = nil
end

return M
