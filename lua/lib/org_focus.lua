--- Focus a single org headline: render only its subtree, in its own buffer.
---
--- The focus buffer is a copy of the subtree's lines (`buftype=acwrite`), so a
--- messy file renders as just that headline. `:w` splices the buffer back into
--- the source buffer's line range and writes *that* buffer: the org file stays
--- the source of truth and nothing outside the range is touched.
---
--- Org resolves "current file" from the buffer name and the headline from the
--- cursor line — neither matches inside a focus buffer — so org actions run
--- against the source buffer at the mapped line (see install_action_hook).

---@class LibOrgFocus
local M = {}

---@class OrgFocusEntry
---@field path string source file
---@field src number source bufnr
---@field start number 1-based line of the headline
---@field end_ number 1-based, inclusive, last line of the subtree
---@field synced string the source range as last synced, '\n'-joined
---@field heading string the headline line as last synced

---@type table<number, OrgFocusEntry> focus bufnr -> what it mirrors
local focused = {}
local hooked = false

--- Loaded buffer for `path` (the file stays authoritative, we never parse disk).
---@param path string
---@return number
local function source_bufnr(path)
  local buf = vim.fn.bufadd(path)
  vim.fn.bufload(buf)
  return buf
end

local function joined(lines)
  return table.concat(lines, '\n')
end

--- The source range as it is in the source buffer right now.
---@param f OrgFocusEntry
---@return string
local function source_range(f)
  return joined(vim.api.nvim_buf_get_lines(f.src, f.start - 1, f.end_, false))
end

--- Re-read the subtree's last line from a fresh parse of the source: an org
--- action can add or remove lines inside the subtree under us.
---@param f OrgFocusEntry
---@return boolean found false when the headline is gone from that line
local function refresh(f)
  local ok, headlines = pcall(function()
    return require('orgmode.api').load(f.path).headlines
  end)
  local function find(list)
    for _, h in ipairs(list or {}) do
      if h.position.start_line == f.start then
        return h
      end
      local child = find(h.headlines)
      if child then
        return child
      end
    end
  end
  local headline = ok and find(headlines)
  if not headline then
    return false
  end
  f.end_ = headline.position.end_line
  return true
end

--- Splice the focus buffer into the source buffer (no disk write), then copy the
--- source range back: an action may have reindented or re-leveled lines.
---@param buf number
---@param f OrgFocusEntry
local function push(buf, f)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  vim.api.nvim_buf_set_lines(f.src, f.start - 1, f.end_, false, lines)
  f.end_ = f.start - 1 + #lines
  f.synced = joined(lines)
  f.heading = lines[1] or ''
end

--- Copy the source range into the focus buffer and mark it clean.
---@param buf number
---@param f OrgFocusEntry
local function pull(buf, f)
  if not refresh(f) then
    vim.notify('org focus: the headline is gone from the source; close this buffer', vim.log.levels.WARN)
    return
  end
  local lines = vim.api.nvim_buf_get_lines(f.src, f.start - 1, f.end_, false)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  f.synced = joined(lines)
  f.heading = lines[1] or ''
  vim.bo[buf].modified = false
end

--- Splice the focus buffer's unsaved edits into the source buffer.
---@param buf number
---@param f OrgFocusEntry
---@return boolean ok false when the source range changed under us
local function flush(buf, f)
  if not vim.bo[buf].modified then
    return true
  end
  if source_range(f) ~= f.synced then
    vim.notify('org focus: the source subtree changed; :e! to reload', vim.log.levels.WARN)
    return false
  end
  push(buf, f)
  vim.bo[buf].modified = false
  return true
end

--- Run org's `action` with the source buffer current at the mapped cursor line,
--- then restore the focus buffer and re-sync it. Installed once on the orgmode
--- module: every org keymap goes through `require('orgmode').action(...)`, and
--- inside a focus buffer "current file" is `orgfocus://…`, which orgmode cannot
--- resolve ("Current file is not a valid org file").
local function install_action_hook()
  if hooked then
    return
  end
  hooked = true

  local org = require('orgmode')
  local action = org.action
  org.action = function(...)
    local buf = vim.api.nvim_get_current_buf()
    local f = focused[buf]
    if not f then
      return action(...)
    end
    if not flush(buf, f) then
      return -- the focus edits conflict with the source; the action is refused
    end

    local win = vim.api.nvim_get_current_win()
    local cursor = vim.api.nvim_win_get_cursor(win)
    local line = math.min(f.start + cursor[1] - 1, vim.api.nvim_buf_line_count(f.src))
    vim.api.nvim_win_set_buf(win, f.src)
    pcall(vim.api.nvim_win_set_cursor, win, { line, cursor[2] })

    local ok, result = pcall(action, ...)

    -- An action that navigated away (opened a file or link) wins: only restore
    -- the focus buffer when the window is still on the source.
    if vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_buf(win) == f.src then
      vim.api.nvim_win_set_buf(win, buf)
      pcall(vim.api.nvim_win_set_cursor, win, cursor)
      pull(buf, f)
    end

    if not ok then
      error(result, 0)
    end
    return result
  end
end

--- Render the subtree at `start_line`..`end_line` (1-based, inclusive) of
--- `path` in a new buffer in the current window.
---@param path string
---@param start_line number
---@param end_line number
---@return number focus bufnr
function M.focus(path, start_line, end_line)
  local src = source_bufnr(path)

  -- Re-focusing the same subtree reuses its buffer (also avoids E95: the
  -- `orgfocus://` name is derived from the source path and start line).
  for b, f in pairs(focused) do
    if not vim.api.nvim_buf_is_valid(b) then
      focused[b] = nil
    elseif f.src == src and f.start == start_line then
      -- Reuse: unsaved focus edits win (flushed into the source), then the
      -- range is pulled again so source-side edits show up too.
      if flush(b, f) then
        pull(b, f)
      end
      vim.api.nvim_win_set_buf(0, b)
      return b
    end
  end

  local lines = vim.api.nvim_buf_get_lines(src, start_line - 1, end_line, false)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].buftype = 'acwrite' -- makes BufWriteCmd below *the* write path
  vim.bo[buf].swapfile = false
  vim.bo[buf].undofile = false
  vim.api.nvim_buf_set_name(buf, string.format('orgfocus://%s#%d', path, start_line))
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].filetype = 'org'

  focused[buf] = {
    path = path,
    src = src,
    start = start_line,
    end_ = end_line,
    synced = joined(lines),
    heading = lines[1] or '',
  }
  vim.api.nvim_create_autocmd('BufWriteCmd', {
    buffer = buf,
    callback = function()
      M.write(buf)
    end,
  })
  vim.api.nvim_create_autocmd('BufReadCmd', {
    buffer = buf,
    callback = function()
      M.reload(buf)
    end,
  })

  vim.api.nvim_win_set_buf(0, buf)
  install_action_hook()
  return buf
end

--- Splice the focus buffer back into the source buffer and write the file.
---@param buf number
function M.write(buf)
  local f = focused[buf]
  if not f or not flush(buf, f) then
    return
  end
  vim.api.nvim_buf_call(f.src, function()
    vim.cmd('silent write')
  end)
end

--- Re-read the subtree from the source buffer (`:e!`). Discards focus edits.
---@param buf number
function M.reload(buf)
  local f = focused[buf]
  if f then
    pull(buf, f)
  end
end

--- Leave the focus buffer for the source buffer at the headline (`:OrgFocus`).
--- Saves first, so the file has what the focus buffer shows.
---@param buf number
function M.goto_source(buf)
  local f = focused[buf]
  if not f then
    return
  end
  M.write(buf)
  if vim.bo[buf].modified then
    return -- the write was refused (conflict), stay where the edits are
  end
  vim.api.nvim_win_set_buf(0, f.src)
  pcall(vim.api.nvim_win_set_cursor, 0, { f.start, 0 })
  vim.cmd('normal! zvzz')
end

--- Focus the headline under the cursor, or go to it in the source file when
--- already focused.
function M.focus_cursor()
  local buf = vim.api.nvim_get_current_buf()
  if focused[buf] then
    M.goto_source(buf)
    return
  end
  if vim.bo.filetype ~= 'org' then
    vim.notify('org focus: not an org buffer', vim.log.levels.WARN)
    return
  end
  local ok, headline = pcall(function()
    return require('orgmode.api').current():get_closest_headline()
  end)
  if not (ok and headline) then
    vim.notify('org focus: no headline under the cursor', vim.log.levels.WARN)
    return
  end
  M.focus(vim.api.nvim_buf_get_name(0), headline.position.start_line, headline.position.end_line)
end

--- Pick a headline with fzf and focus it.
function M.focus_search()
  lib.org_fzf.search_headings({
    on_confirm = function(item)
      M.focus(item.filename, item.line_number, item.end_line)
    end,
  })
end

--- Register :OrgFocus and :OrgFocusSearch.
function M.setup_commands()
  vim.api.nvim_create_user_command('OrgFocus', M.focus_cursor, {
    desc = 'org: focus the headline under the cursor (or go to it)',
  })
  vim.api.nvim_create_user_command('OrgFocusSearch', M.focus_search, {
    desc = 'org: pick a headline (fzf) and focus it',
  })
end

return M
