--- Intra-line diff emphasis ("word diff"), delta north star.
---
--- Given the lines of a unified-diff buffer (fugitive `:Git log -p`,
--- `:Git show`, `:Git diff` — anything with `filetype=git`), compute the
--- byte ranges inside `-`/`+` lines that actually changed, so they can be
--- painted with emph backgrounds (`PlusEmph`/`MinusEmph`) like delta's
--- plus-emph-style/minus-emph-style.
---
--- Algorithm mirrors delta/gitsigns word diff:
---   1. Scan lines; accumulate each contiguous run of `-` lines and the
---      immediately following run of `+` lines (unified format guarantees
---      deletions precede additions within one change segment).
---   2. Tokenize both runs into words, diff the two token sequences with
---      vim.text.diff(), and mark every unmatched token's byte range.
---   3. Merge adjacent marked tokens on a line into one span.
---
--- Pure functions only (unit-tested with luajit); the sequence diff is
--- injected so tests can substitute a naive LCS reference implementation.

local M = {}

---@class DiffEmphRegion
---@field row integer 0-based buffer row
---@field col integer 0-based inclusive start byte col
---@field end_ integer 0-based exclusive end byte col
---@field kind 'add'|'del'

---@param line string
---@return {text: string, col: integer, end_: integer}[]
local function tokenize(line)
  local tokens = {}
  local pos = 1
  while true do
    local s, e = line:find('%S+', pos)
    if not s then
      break
    end
    tokens[#tokens + 1] = { text = line:sub(s, e), col = s - 1, end_ = e }
    pos = e + 1
  end
  return tokens
end

--- Emit regions for the changed tokens of one paired -/+ block.
---@param del_rows {row: integer, line: string}[] maximal `-` run
---@param add_rows {row: integer, line: string}[] maximal `+` run
---@param difffn fun(a: string, b: string): integer[][]
---@return DiffEmphRegion[]
local function block_regions(del_rows, add_rows, difffn)
  --- One diff input line per word token; `meta` maps each 1-based diff line
  --- index back to its byte span. Token-less lines (blank +/- lines) have
  --- nothing to paint, so they contribute no diff line.
  local function build(rows)
    local texts, meta = {}, {}
    for _, r in ipairs(rows) do
      for _, t in ipairs(tokenize(r.line)) do
        texts[#texts + 1] = t.text
        meta[#meta + 1] = { row = r.row, col = t.col, end_ = t.end_ }
      end
    end
    return table.concat(texts, '\n') .. '\n', meta
  end

  local del_text, del_meta = build(del_rows)
  local add_text, add_meta = build(add_rows)
  local hunks = difffn(del_text, add_text)
  local regions = {}

  ---@param meta table diff line idx -> {row, col, end_}
  ---@param kind string
  local function emit(meta, start_idx, count, kind)
    for i = start_idx, start_idx + count - 1 do
      local m = meta[i]
      if m then -- guard phantom indices from a shorter opposite block
        local last = regions[#regions]
        -- Merge with previous region when same row, same kind, gap <= 1
        -- byte (adjacent tokens paint as one span).
        if last and last.row == m.row and last.kind == kind and m.col <= last.end_ + 1 then
          last.end_ = math.max(last.end_, m.end_)
        else
          regions[#regions + 1] = { row = m.row, col = m.col, end_ = m.end_, kind = kind }
        end
      end
    end
  end

  for _, h in ipairs(hunks) do
    emit(del_meta, h[1], h[2], 'del')
    emit(add_meta, h[3], h[4], 'add')
  end

  return regions
end

--- Compute all emphasis regions for a buffer's lines.
---@param lines string[] buffer lines
---@param difffn? fun(a: string, b: string): integer[][] defaults to vim.text.diff(indices)
---@return DiffEmphRegion[] regions sorted by row
function M.plan(lines, difffn)
  difffn = difffn or function(a, b)
    return vim.text.diff(a, b, { result_type = 'indices' })
  end

  local regions = {}
  local del_rows, add_rows = {}, {}

  local function flush()
    if #del_rows > 0 and #add_rows > 0 then
      vim.list_extend(regions, block_regions(del_rows, add_rows, difffn))
    end
    del_rows, add_rows = {}, {}
  end

  for idx, line in ipairs(lines) do
    local row = idx - 1
    local c = line:sub(1, 1)
    -- `--- `/`+++ ` are the old/new file headers, never hunk body lines
    -- (same tradeoff as diff-colors.lua's terminal classifier: a deleted
    -- line whose content literally starts with `-- ` is misread as a header).
    local is_del = c == '-' and line:sub(1, 4) ~= '--- '
    local is_add = c == '+' and line:sub(1, 4) ~= '+++ '

    if is_del then
      if #add_rows > 0 then
        flush() -- deletions always precede additions within a segment
      end
      del_rows[#del_rows + 1] = { row = row, line = line:sub(2) }
    elseif is_add then
      add_rows[#add_rows + 1] = { row = row, line = line:sub(2) }
    else
      flush() -- context, @@ header, metadata, commit message, EOF separators
    end
  end
  flush()

  return regions
end

return M
