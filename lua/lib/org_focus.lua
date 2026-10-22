--- Focus a single org headline: render only its subtree, in its own buffer.
---
--- The focus buffer is a copy of the subtree's lines (`buftype=acwrite`), so a
--- messy file renders as just that headline. `:w` splices the buffer back into
--- the source buffer's line range and writes *that* buffer: the org file stays
--- the source of truth and nothing outside the range is touched. Two-way sync
--- stays manual on the read side — `:e!` in the focus buffer re-reads the
--- subtree from the source.

---@class LibOrgFocus
local M = {}

---@type table<number, { src: number, start: number, end_: number, heading: string }>
--- focus bufnr -> source bufnr + the 1-based inclusive line range it mirrors
local focused = {}

--- Loaded buffer for `path` (the file stays authoritative, we never touch disk).
---@param path string
---@return number
local function source_bufnr(path)
  local buf = vim.fn.bufadd(path)
  vim.fn.bufload(buf)
  return buf
end

--- Has the source moved out from under us? Compares the headline line we last
--- synced with what is at that line now (nil when the line is gone).
---@param f table
---@return boolean
local function stale(f)
  return vim.api.nvim_buf_get_lines(f.src, f.start - 1, f.start, false)[1] ~= f.heading
end

--- Render the subtree at `start_line`..`end_line` (1-based, inclusive) of
--- `path` in a new buffer in the current window.
---@param path string
---@param start_line number
---@param end_line number
---@return number focus bufnr
function M.focus(path, start_line, end_line)
  local src = source_bufnr(path)
  local lines = vim.api.nvim_buf_get_lines(src, start_line - 1, end_line, false)

  -- Re-focusing the same subtree reuses its buffer (also avoids E95: the
  -- `orgfocus://` name is derived from the source path and start line).
  for b, f in pairs(focused) do
    if not vim.api.nvim_buf_is_valid(b) then
      focused[b] = nil
    elseif f.src == src and f.start == start_line then
      vim.api.nvim_win_set_buf(0, b)
      return b
    end
  end

  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].buftype = 'acwrite' -- makes BufWriteCmd below *the* write path
  vim.bo[buf].swapfile = false
  vim.bo[buf].undofile = false
  vim.api.nvim_buf_set_name(buf, string.format('orgfocus://%s#%d', path, start_line))
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].filetype = 'org'

  focused[buf] = { src = src, start = start_line, end_ = end_line, heading = lines[1] or '' }
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
  return buf
end

--- Splice the focus buffer back into the source buffer and write the file.
---@param buf number
function M.write(buf)
  local f = focused[buf]
  if not f then
    return
  end
  if vim.bo[f.src].modified then
    vim.notify('org focus: source buffer has unsaved changes, save it first', vim.log.levels.WARN)
    return
  end
  if stale(f) then
    vim.notify('org focus: the source headline changed; :e! to reload', vim.log.levels.WARN)
    return
  end

  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  vim.api.nvim_buf_set_lines(f.src, f.start - 1, f.end_, false, lines)
  f.end_ = f.start - 1 + #lines
  f.heading = lines[1] or ''
  vim.api.nvim_buf_call(f.src, function()
    vim.cmd('silent write')
  end)
  vim.bo[buf].modified = false
end

--- Re-read the subtree from the source buffer (`:e!`). Discards focus edits.
---@param buf number
function M.reload(buf)
  local f = focused[buf]
  if not f then
    return
  end
  if stale(f) then
    vim.notify('org focus: the source headline changed; cannot reload', vim.log.levels.WARN)
    return
  end
  local lines = vim.api.nvim_buf_get_lines(f.src, f.start - 1, f.end_, false)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modified = false
end

--- Focus the headline under the cursor.
function M.focus_cursor()
  if focused[vim.api.nvim_get_current_buf()] then
    vim.notify('org focus: already focused', vim.log.levels.WARN)
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
    desc = 'org: focus the headline under the cursor',
  })
  vim.api.nvim_create_user_command('OrgFocusSearch', M.focus_search, {
    desc = 'org: pick a headline (fzf) and focus it',
  })
end

return M
