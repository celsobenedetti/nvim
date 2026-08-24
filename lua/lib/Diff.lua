--- Diff: simple git viewer on top of fugitive.
--- A dedicated tab shows the fugitive raw-output buffer (`filetype=git`)
--- for the requested diff; a quickfix list below has one entry per affected
--- file, pointing at the file's `diff --git` header (the treesitter `block`
--- start) inside the buffer. A buffer-local <CR> in the quickfix window
--- jumps the top window to that line — native nvim <CR> would split a new
--- window instead, because fugitive's `Git` output buffers are
--- `buftype=nowrite` and the native jump only reuses windows whose buffer
--- is a "normal" buffer (see M.install_qf_jump).
---
--- The per-file sections are located with the `diff` treesitter grammar,
--- which after/plugin/autocmds.lua aliases onto the `git` filetype fugitive
--- hardcodes on its patch buffers (:Git diff / :Git show).
---@class LibDiff
local M = {}

--- Query for per-file blocks: capture the `block` node (starts at the
--- `diff --git` line), the `+++ b/x` filename (`new_file`), and the
--- filenames in the `diff --git` command line (the grammar folds both
--- paths into one `filename` node; the `b/` side is its last token).
--- Parsed once; independent of the parser being installed.
local BLOCK_QUERY =
  vim.treesitter.query.parse('diff', '(block (command (filename) @file) (new_file (filename) @new)?) @block')

--- Per-hunk +/- content lines, for per-file change summaries. `addition` /
--- `deletion` are the `+`/`-` body lines (headers, `@@` locations, and
--- context lines are other node types). Two patterns so hunks that contain
--- only additions or only deletions still count.
local STATS_QUERY = vim.treesitter.query.parse(
  'diff',
  [[
(changes (addition) @add)
(changes (deletion) @del)
]]
)

-- `query.captures` is an id -> name list; build the name -> id map for
-- `iter_matches`/`iter_captures` results (ids are per-query).
local CAPTURE_IDS = {}
for _, q in ipairs({ BLOCK_QUERY, STATS_QUERY }) do
  for id, name in ipairs(q.captures) do
    CAPTURE_IDS[name] = id
  end
end

---Start row of the `block` a node belongs to, or nil.
---@param node TSNode
---@return integer?
local function block_start(node)
  local p = node:parent()
  while p do
    if p:type() == 'block' then
      return p:start()
    end
    p = p:parent()
  end
  return nil
end

local has_icons, mini_icons = pcall(require, 'mini.icons')

---Filetype glyph and its highlight for a path ('' / nil when mini.icons is
---unavailable).
---@param path string
---@return string glyph
---@return string? hl
local function file_icon(path)
  if not has_icons then
    return '', nil
  end
  local glyph, hl = mini_icons.get('file', path)
  return glyph or '', hl
end

---Delta-style change summary: `+N -M`, zero sides omitted.
---@param adds integer
---@param dels integer
---@return string
local function summary_text(adds, dels)
  local s = ''
  if adds > 0 then
    s = s .. ' +' .. adds
  end
  if dels > 0 then
    s = s .. ' -' .. dels
  end
  return s
end

---New path from a filename node: strip the standard git prefix
---(`a/`, `b/`, `i/`, `w/` — git >= 2.50 uses `i/`/`w/` for index/worktree
---diffs), tolerating git's C-style quoting of paths with special
---characters (`"b/foo bar.txt"`).
---@param node TSNode
---@param bufnr number
---@return string
local function new_path(node, bufnr)
  local text = vim.treesitter.get_node_text(node, bufnr)
  -- command-line fallback: `i/x w/x` is one node; the new path is the last token
  text = text:match('(%S+)$') or text
  return text:gsub('^"', ''):gsub('^[abiw]/', ''):gsub('"$', '')
end

---Parse per-file blocks from a fugitive patch buffer: one entry per
---treesitter `block`, with its 0-based header row, new path, mini.icons
---glyph + hl, and the `+N -M` change summary. Shared by the quickfix list
---(M.parse_items) and the inline filepath bars (lib.diff_filepath).
---@param bufnr number
---@return table[] blocks {row, lnum, path, icon, icon_hl, adds, dels, summary}
M.parse_blocks = function(bufnr)
  local tree = vim.treesitter.get_parser(bufnr):parse()[1]
  local root = tree:root()

  -- Per-block +/- line counts, keyed by block start row.
  local stats = {}
  local add_cap, del_cap = CAPTURE_IDS.add, CAPTURE_IDS.del
  for id, node in STATS_QUERY:iter_captures(root, bufnr, 0, -1) do
    local sr = block_start(node)
    if sr then
      local s = stats[sr] or { adds = 0, dels = 0 }
      if id == add_cap then
        s.adds = s.adds + 1
      else
        s.dels = s.dels + 1
      end
      stats[sr] = s
    end
  end

  local blocks = {}
  local block_cap, file_cap, new_cap = CAPTURE_IDS.block, CAPTURE_IDS.file, CAPTURE_IDS.new
  for _, match in BLOCK_QUERY:iter_matches(root, bufnr, 0, -1) do
    local block = match[block_cap] and match[block_cap][1]
    if block then
      -- `+++ b/x` when present (cleanest); otherwise the last command filename
      local name_node = (match[new_cap] and match[new_cap][1]) or (match[file_cap] and match[file_cap][1])
      local path = name_node and new_path(name_node, bufnr) or ''
      local icon, icon_hl = file_icon(path)
      local s = stats[block:start()]
      local adds = s and s.adds or 0
      local dels = s and s.dels or 0
      blocks[#blocks + 1] = {
        row = block:start(),
        lnum = block:range() + 1,
        path = path,
        icon = icon,
        icon_hl = icon_hl,
        adds = adds,
        dels = dels,
        summary = summary_text(adds, dels),
      }
    end
  end

  return blocks
end

---Collect quickfix items from a fugitive patch buffer: one entry per
---treesitter `block`, `lnum` = the block's header line. `text` is a
---tabular row rendered by M.qf_line (`'quickfixtextfunc'`, which replaces
---the native `file|lnum|text` format — including its leading-whitespace
---stripping): right-aligned lnum column, mini.icons glyph + path padded to
---the widest label, and the `+N -M` summary. Binary/rename sections
---without hunks show just the padded path.
---@param bufnr number
---@return table[] items quickfix items {bufnr, lnum, text}
M.parse_items = function(bufnr)
  -- Collect rows first so the text can be padded to the widest lnum/label.
  local rows = {}
  for _, b in ipairs(M.parse_blocks(bufnr)) do
    rows[#rows + 1] = {
      lnum = b.lnum,
      label = b.icon ~= '' and (b.icon .. ' ' .. b.path) or b.path,
      summary = b.summary,
    }
  end

  local max_lnum_w, max_label_w = 0, 0
  for _, r in ipairs(rows) do
    max_lnum_w = math.max(max_lnum_w, vim.fn.strwidth(tostring(r.lnum)))
    max_label_w = math.max(max_label_w, vim.fn.strwidth(r.label))
  end

  local items = {}
  for _, r in ipairs(rows) do
    local text = string.rep(' ', max_lnum_w - vim.fn.strwidth(tostring(r.lnum)))
      .. r.lnum
      .. ' '
      .. r.label
      .. string.rep(' ', max_label_w - vim.fn.strwidth(r.label) + 1)
      .. r.summary
    items[#items + 1] = { bufnr = bufnr, lnum = r.lnum, text = text }
  end
  return items
end

---`'quickfixtextfunc'` renderer for `:Diff` lists: return each entry's
---precomputed text verbatim. Replacing the native `file|lnum|text` format
---keeps the leading padding (native rendering runs `skipwhite()` on the
---text) and drops the fugitive temp-file path from the display. The jump
---target is unaffected — `bufnr`/`lnum` drive that.
---@param info table {id, start_idx, end_idx}
---@return string[]
M.qf_line = function(info)
  local items = vim.fn.getqflist({ id = info.id, items = 1 }).items or {}
  local lines = {}
  for idx = info.start_idx, info.end_idx do
    lines[#lines + 1] = items[idx] and items[idx].text or ''
  end
  return lines
end

--- Winbar texts for `:Diff` quickfix lists, keyed by qf list id. Looked up
--- at render time by after/plugin/winbar.lua's get_winbar() using the
--- current list id, so the bar is self-cleaning: a new list (:grep, another
--- :Diff) has a new id and simply doesn't match. Old ids stay valid on the
--- quickfix stack (each setqflist pushes), so `:colder` back to a previous
--- :Diff list keeps its bar. Entries are short strings; a session's worth
--- of :Diff calls costs a few KB.
local winbars = {}

---Record the winbar text for a quickfix list (called by M.open).
---@param qfid integer
---@param text string
M.record_winbar = function(qfid, text)
  winbars[qfid] = text
end

---Winbar text for a quickfix list, or nil when this module didn't create
---the list (grep, fugitive Gclog, … render their own or nothing).
---@param qfid integer
---@return string?
M.winbar_text = function(qfid)
  return winbars[qfid]
end

---Install a `<CR>` mapping on the current (quickfix) window's buffer that
---reuses the window showing the diff buffer instead of letting nvim split a
---new one. nvim's native quickfix jump only reuses windows whose buffer is
---a "normal" buffer (`buftype` empty); fugitive's `Git` output buffers are
---`buftype=nowrite`, so the default <CR> always opens a new split above the
---quickfix window. The mapping is scoped to `:Diff` lists via the qf title
---(the qf buffer is shared across lists, e.g. `:grep` reuses it); other
---lists fall through to the native `:cc`.
M.install_qf_jump = function()
  local qf_buf = vim.api.nvim_win_get_buf(vim.api.nvim_get_current_win())
  vim.keymap.set('n', '<CR>', function()
    -- The qf window's line number equals the entry number (native <CR> is
    -- `:.cc`); the list's `idx` does NOT follow the cursor.
    local qf_line = vim.fn.line('.')
    local list = vim.fn.getqflist({ items = 1, title = 1 })
    local item = list.items and list.items[qf_line]
    if not item or item.bufnr == 0 or not (list.title or ''):match('^Diff') then
      vim.cmd('cc ' .. qf_line) -- not ours (or nothing to jump to): native behavior
      return
    end
    -- All :Diff items point into the diff buffer; move to a window already
    -- showing it (never the quickfix window), then let `:cc <nr>` jump there.
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
      local buf = vim.api.nvim_win_get_buf(win)
      if buf == item.bufnr and vim.bo[buf].buftype ~= 'quickfix' then
        vim.api.nvim_set_current_win(win)
        break
      end
    end
    vim.cmd('cc ' .. qf_line)
  end, { buffer = qf_buf, desc = 'Diff: jump top window to quickfix entry' })
end

---Open `:Diff` in a dedicated tab: fugitive patch on top, quickfix of
---changed files below (focused). Completion is tracked through fugitive's
---own async job (fugitive#Result/fugitive#Wait) — the buffer is empty until
---the job finishes, so the treesitter parse must wait for it
---(docs/diff-emph.md gotcha #3). A non-zero git exit status means failure
---(the error stays visible in the tab); an empty patch with status 0 closes
---the tab again.
---@param args string[]|string 0, 1, or 2 revision arguments; a single
---argument containing `..` (e.g. `dev..HEAD`, `dev...HEAD`) is treated as
---a diff range rather than a `git show` rev. Also accepts the legacy call
---`open(rev1, rev2)` (two strings) — the pre-0913e74 `:Diff`
---command in after/plugin/git.lua called it that way, and a running nvim
---session registered before the fix still does (the lib itself loads
---lazily from disk, so the old command pairs with the new module).
M.open = function(args, ...)
  if type(args) ~= 'table' then
    args = { args, ... }
  end
  local n = #args
  local cmd, title, qf_title, git_args
  if n == 0 then
    git_args = 'diff'
    qf_title = 'Diff (working tree)'
  elseif n == 1 then
    -- A single arg with `..` (two- or three-dot) is a range, not a rev:
    -- `git diff -p dev..HEAD` / `dev...HEAD`. Valid refnames never
    -- contain `..` (git check-ref-format), so the check is unambiguous.
    git_args = (args[1]:find('..', 1, true) and 'diff -p ' or 'show ') .. args[1]
    qf_title = 'Diff ' .. args[1]
  else
    git_args = 'diff -p ' .. args[1] .. ' ' .. args[2]
    qf_title = 'Diff ' .. args[1] .. '..' .. args[2]
  end
  cmd = 'tab Git ' .. git_args
  title = 'git ' .. git_args

  lib.tab.set_next_name(config.icons.git.git .. title)
  local ok, err = pcall(vim.cmd, cmd)
  if not ok then
    lib.tab.set_next_name(nil)
    vim.notify('Diff: ' .. tostring(err), vim.log.levels.ERROR)
    return
  end

  -- fugitive runs `Git ...` as a job writing into the new buffer; ask it
  -- for the job state and wait (fallback covers the entry being reaped
  -- before we look, e.g. fast completion).
  local bufnr = vim.api.nvim_win_get_buf(0)
  local result = vim.fn['fugitive#Result'](bufnr)
  if next(result) == nil then
    result = vim.fn['fugitive#Result']()
  end
  if result.job ~= nil then
    vim.fn['fugitive#Wait'](result, 5000)
  end

  local ok_parse, items = pcall(M.parse_items, bufnr)
  if not ok_parse then
    vim.notify('Diff: treesitter diff parser unavailable: ' .. tostring(items), vim.log.levels.WARN)
    return
  end

  if #items > 0 then
    -- per-list quickfixtextfunc renders the tabular rows (M.qf_line); it
    -- overrides the native file|lnum|text format and survives only while
    -- this list is current.
    vim.fn.setqflist({}, ' ', {
      title = qf_title,
      items = items,
      quickfixtextfunc = 'v:lua.lib.Diff.qf_line',
    })
    -- winbar tail for the qf window: `<icon> Diff <args>`; the
    -- after/plugin/winbar.lua quickfix branch prefixes it with the buffer
    -- name and a ` > ` separator (`[Quickfix List] > <icon> Diff <args>`).
    local args_text = n > 0 and (' ' .. table.concat(args, ' ')) or ''
    M.record_winbar(vim.fn.getqflist({ id = 0 }).id, config.icons.git.git .. ' Diff' .. args_text)
    vim.cmd('botright copen')
    M.install_qf_jump()
    return
  end

  if result.exit_status == nil then
    -- Wait timed out (huge diff); leave the tab open for it to finish.
    vim.notify('Diff: diff still rendering', vim.log.levels.INFO)
  elseif result.exit_status == 0 then
    vim.cmd('tabclose')
    vim.notify('Diff: no changes' .. (n > 0 and (' between ' .. table.concat(args, ' ')) or ''), vim.log.levels.INFO)
  else
    vim.notify('Diff: git exited with ' .. result.exit_status .. '; see the error in the new tab', vim.log.levels.WARN)
  end
end

---Nodes of `kind` in document order (their start rows are ascending:
---blocks/hunks never overlap).
---@param root TSNode
---@param kind string
---@return TSNode[]
local function collect_nodes(root, kind)
  local nodes = {}
  local function walk(node)
    for child in node:iter_children() do
      if child:type() == kind then
        nodes[#nodes + 1] = child
      end
      walk(child)
    end
  end
  walk(root)
  return nodes
end

---Jump the cursor to the `count`-th `kind` section before/after the cursor:
---`'block'` = per-file section (`diff --git` header), `'hunk'` = per-hunk
---section (`@@` header). `dir = 1` goes forward (next), `-1` backward
---(previous); strict, so a repeated press always moves past the current
---section. No-op when nothing matches in that direction (or the buffer has
---no `diff` parse tree). Leaves a jumplist entry so <C-o> returns.
---@param kind 'block' | 'hunk'
---@param dir 1 | -1
M.goto_node = function(kind, dir)
  local bufnr = vim.api.nvim_get_current_buf()
  local ok, tree = pcall(function()
    return vim.treesitter.get_parser(bufnr):parse()[1]
  end)
  if not ok or not tree then
    return
  end

  local cur = vim.fn.line('.') - 1 -- 0-based cursor row
  local rows = {}
  for _, node in ipairs(collect_nodes(tree:root(), kind)) do
    rows[#rows + 1] = node:start()
  end

  local count = vim.v.count1
  local target
  if dir == 1 then
    local i = 1
    while i <= #rows and rows[i] <= cur do
      i = i + 1
    end
    target = rows[i + count - 1]
  else
    local i = #rows
    while i >= 1 and rows[i] >= cur do
      i = i - 1
    end
    target = rows[i - count + 1]
  end
  if not target then
    return
  end

  vim.cmd("normal! m'") -- jumplist entry; <C-o> returns
  vim.api.nvim_win_set_cursor(0, { target + 1, 0 })
end

return M
