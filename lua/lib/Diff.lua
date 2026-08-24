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

---Per-block +/- line counts, keyed by block start row (0-based). Blocks
---without hunks (binary, rename, pure metadata) have no entry.
---@param root TSNode
---@param bufnr number
---@return table<integer, {adds:integer, dels:integer}>
local function block_stats(root, bufnr)
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
  return stats
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
  local stats = block_stats(root, bufnr)

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

-- ---------------------------------------------------------------------------
-- Diff tree sidebar: an InspectTree-like outline of a `filetype=git` diff
-- buffer on the left, showing only per-file `block`s (top level, rendered
-- `<icon> <path> <summary>`) and their `hunk`s (nested `@@` lines). Focus
-- (CursorMoved) highlights the section in the diff buffer and scrolls it into
-- view; <CR> jumps there; the diff buffer's own cursor keeps the tree in sync
-- (bidirectional). Blocks fold their hunks with native expr folding.
-- ---------------------------------------------------------------------------

local TREE_NS = vim.api.nvim_create_namespace('lib.diff.tree')

---lib.diff_filepath handle, required on first use: it requires this module at
---its own load time, so requiring it at the top of the file would be a
---load-order cycle.
local function filepath_bar()
  return require('lib.diff_filepath')
end

---New path for a `block` node: prefer the `+++ b/x` line unless it names
---`/dev/null` (git emits that for deletions), else the last path token of the
---`diff --git` command line (covers binary/rename sections and deletions).
---Returns '' when neither is parseable.
---@param block TSNode
---@param bufnr number
---@return string
local function block_path(block, bufnr)
  local command_text = nil
  local new_file_text = nil
  for child in block:iter_children() do
    local t = child:type()
    if t == 'command' then
      command_text = new_path(child, bufnr)
    elseif t == 'new_file' then
      new_file_text = new_path(child, bufnr)
    end
  end
  if new_file_text and new_file_text ~= '/dev/null' then
    return new_file_text
  end
  return command_text or ''
end

---The `@@` header line of a hunk (git appends the enclosing function/class
---heading after the second `@@`, so this reads e.g. `@@ -10,3 +10,4 @@ foo()`).
---@param hunk TSNode
---@param bufnr number
---@return string
local function hunk_text(hunk, bufnr)
  for child in hunk:iter_children() do
    if child:type() == 'location' then
      return vim.treesitter.get_node_text(child, bufnr)
    end
  end
  return '@@'
end

---One row per block/hunk in document order, for the diff tree sidebar.
---Blocks are top-level entries (`path` + `summary`); hunks are nested under
---their block (`text` = the `@@` line). `lnum` is the 1-based jump target
---(block: `diff --git` header; hunk: `@@` header); `range` is the node's
---0-based span (block: whole section, used for containment; hunk: whole hunk,
---used for both containment and hover highlight).
---@param bufnr number
---@return table[]
M.tree_rows = function(bufnr)
  local tree = vim.treesitter.get_parser(bufnr):parse()[1]
  local root = tree:root()
  local stats = block_stats(root, bufnr)

  local rows = {}
  local function walk(node)
    for child in node:iter_children() do
      if child:type() == 'block' then
        local path = block_path(child, bufnr)
        local s = stats[child:start()]
        rows[#rows + 1] = {
          kind = 'block',
          lnum = child:start() + 1,
          path = path,
          summary = summary_text(s and s.adds or 0, s and s.dels or 0),
          range = { child:range() },
        }
        for _, hunk in ipairs(collect_nodes(child, 'hunk')) do
          rows[#rows + 1] = {
            kind = 'hunk',
            lnum = hunk:start() + 1,
            text = hunk_text(hunk, bufnr),
            range = { hunk:range() },
          }
        end
      else
        walk(child)
      end
    end
  end
  walk(root)
  return rows
end

---Foldexpr for the tree window (`foldmethod=expr`): a block is a fold header
---(`>1` starts the fold) when it has hunks; hunks sit inside it (`1`). Blocks
---without hunks (binary/rename) don't fold.
M.tree_foldexpr = function()
  local rows = vim.b.diff_tree_rows
  local r = rows and rows[vim.v.lnum]
  if not r then
    return '0'
  end
  if r.kind == 'block' then
    local next = rows[vim.v.lnum + 1]
    return (next and next.kind == 'hunk') and '>1' or '0'
  end
  return '1'
end

---Render a tree row into a display line. Block rows are `<icon> <path>`,
---padded so their `+N -M` summaries align (no padding when the summary is
---empty); hunk rows are two-space-indented `@@` lines under their block.
---@param row table
---@param label_w integer width of the widest block label
---@return string
local function render_row(row, label_w)
  if row.kind == 'block' then
    local icon = file_icon(row.path)
    local label = icon ~= '' and (icon .. ' ' .. row.path) or row.path
    if row.summary == '' then
      return label
    end
    return label .. string.rep(' ', label_w - vim.fn.strwidth(label) + 1) .. row.summary
  end
  return '  ' .. row.text
end

---Tree row (1-based) whose range contains the given 0-based source row,
---preferring the deepest (a hunk over its enclosing block), or nil.
---@param rows table[]
---@param srow integer
---@return integer?
M.tree_row_containing = function(rows, srow)
  for i = #rows, 1, -1 do
    local start_row, _, end_row = unpack(rows[i].range)
    if srow >= start_row and srow <= end_row then
      return i
    end
  end
  return nil
end

---0-based source highlight range for a tree row: blocks highlight just their
---`diff --git` header line; hunks highlight their whole node range.
---@param bufnr number
---@param row table
---@return integer srow
---@return integer erow
---@return integer ecol
M.tree_hl_range = function(bufnr, row)
  if row.kind == 'block' then
    local srow = row.lnum - 1
    return srow, srow, #(vim.api.nvim_buf_get_lines(bufnr, srow, srow + 1, false)[1] or '')
  end
  local srow, _, erow, ecol = unpack(row.range)
  return srow, erow, math.max(0, ecol)
end

---Move the diff buffer's cursor to the tree row under the cursor, reusing a
---window that already shows it (never the tree window itself).
local function jump_to_row(tree_buf)
  local row = vim.fn.line('.')
  local rows = vim.b[tree_buf].diff_tree_rows
  local r = rows and rows[row]
  local src_buf = vim.b[tree_buf].diff_tree_src
  if not r or not src_buf or not vim.api.nvim_buf_is_loaded(src_buf) then
    return
  end
  local src_win
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if win ~= vim.api.nvim_get_current_win() and vim.api.nvim_win_get_buf(win) == src_buf then
      src_win = win
      break
    end
  end
  if not src_win then
    return
  end
  vim.api.nvim_set_current_win(src_win)
  vim.api.nvim_win_set_cursor(src_win, { r.lnum, 0 })
  vim.cmd.norm('zt')
end

---Highlight the section under the tree cursor in the source buffer and scroll
---the source window to reveal it (without moving its cursor). Hunks highlight
---their whole range with Visual; blocks light up lib.diff_filepath's overlay
---bar instead — the header line's visible pixels belong to that extmark, whose
---virt_text chunks no second extmark can restyle. Exposed as M.tree_focus for
---the headless integration test (CursorMoved never fires under --headless).
M.tree_focus = function(tree_buf, tree_win)
  local row = vim.fn.line('.')
  local rows = vim.b[tree_buf].diff_tree_rows
  local r = rows and rows[row]
  local src_buf = vim.b[tree_buf].diff_tree_src
  if not r or not src_buf or not vim.api.nvim_buf_is_loaded(src_buf) then
    return
  end

  vim.api.nvim_buf_clear_namespace(src_buf, TREE_NS, 0, -1)

  local srow, erow, ecol = M.tree_hl_range(src_buf, r)

  if r.kind == 'block' then
    -- Re-emit the hovered block's bar on the hover palette; a plain extmark
    -- here would only paint over the raw text, which DiffFileBar's fg==bg
    -- already keeps invisible beneath the overlay.
    filepath_bar().set_hover(src_buf, r.lnum - 1)
  else
    filepath_bar().set_hover(src_buf, nil)
    vim.api.nvim_buf_set_extmark(src_buf, TREE_NS, srow, 0, {
      end_row = erow,
      end_col = ecol,
      hl_group = 'Visual',
    })
  end

  -- Scroll without moving the cursor: winrestview with only topline set
  -- leaves the cursor where it is (unlike win_set_cursor).
  local src_win = vim.b[tree_buf].diff_tree_src_win
  if not src_win or not vim.api.nvim_win_is_valid(src_win) then
    local wins = vim.fn.win_findbuf(src_buf)
    src_win = wins[1]
    vim.b[tree_buf].diff_tree_src_win = src_win
  end
  if src_win then
    vim.api.nvim_win_call(src_win, function()
      local topline = vim.fn.line('w0')
      local botline = vim.fn.line('w$')
      if srow + 1 < topline or srow + 1 > botline then
        vim.fn.winrestview({ topline = srow + 1 })
      end
    end)
  end
end

---Toggle the diff tree sidebar for the current buffer: a left-side vertical
---split listing each per-file `block` (`<icon> <path> <summary>`) with its
---`hunk`s (`@@` lines) nested underneath. Focus (CursorMoved) highlights the
---section in the diff buffer and scrolls it into view; <CR> jumps there; the
---diff buffer's own cursor keeps the tree in sync. Blocks fold their hunks
---with native expr folding (`zc`/`zo`). Requires the current buffer to parse
---as `diff` (the git->diff alias in after/plugin/autocmds.lua makes fugitive
---patch buffers qualify).
M.open_tree = function()
  local src_buf = vim.api.nvim_get_current_buf()

  -- Toggle off: close the tree window this buffer already owns.
  local existing = vim.b[src_buf].diff_tree_win
  if existing and vim.api.nvim_win_is_valid(existing) then
    vim.api.nvim_win_close(existing, true)
    vim.b[src_buf].diff_tree_win = nil
    if vim.b[src_buf].diff_tree_group then
      pcall(vim.api.nvim_del_augroup_by_id, vim.b[src_buf].diff_tree_group)
      vim.b[src_buf].diff_tree_group = nil
    end
    return
  end

  local ok, rows = pcall(M.tree_rows, src_buf)
  if not ok then
    vim.notify('DiffTree: ' .. tostring(rows), vim.log.levels.WARN)
    return
  end
  if #rows == 0 then
    vim.notify('DiffTree: no diff sections in this buffer', vim.log.levels.INFO)
    return
  end

  local src_win = vim.api.nvim_get_current_win()

  -- Build display lines, padding block labels so summaries align.
  local label_w = 0
  for _, r in ipairs(rows) do
    if r.kind == 'block' then
      local icon = file_icon(r.path)
      local label = icon ~= '' and (icon .. ' ' .. r.path) or r.path
      label_w = math.max(label_w, vim.fn.strwidth(label))
    end
  end
  local lines = {}
  for _, r in ipairs(rows) do
    lines[#lines + 1] = render_row(r, label_w)
  end

  vim.cmd('leftabove 30vnew')
  local tree_win = vim.api.nvim_get_current_win()
  local tree_buf = vim.api.nvim_get_current_buf()

  vim.bo[tree_buf].buftype = 'nofile'
  vim.bo[tree_buf].buflisted = false
  vim.bo[tree_buf].bufhidden = 'wipe'
  vim.bo[tree_buf].swapfile = false
  vim.bo[tree_buf].filetype = 'diff-tree'
  vim.bo[tree_buf].modifiable = true
  vim.api.nvim_buf_set_lines(tree_buf, 0, -1, false, lines)
  -- Hunk rows dimmed as comments (block rows keep the default look). The tree
  -- buffer is wiped on close, so these marks need no explicit teardown.
  for i, r in ipairs(rows) do
    if r.kind == 'hunk' then
      vim.api.nvim_buf_set_extmark(tree_buf, TREE_NS, i - 1, 0, {
        end_row = i,
        hl_group = 'Comment',
      })
    end
  end
  vim.bo[tree_buf].modifiable = false

  vim.wo[tree_win].wrap = false
  vim.wo[tree_win].foldmethod = 'expr'
  vim.wo[tree_win].foldexpr = 'v:lua.lib.Diff.tree_foldexpr()'
  vim.wo[tree_win].foldlevel = 99

  vim.b[tree_buf].diff_tree_rows = rows
  vim.b[tree_buf].diff_tree_src = src_buf
  vim.b[tree_buf].diff_tree_src_win = src_win
  vim.b[src_buf].diff_tree_win = tree_win

  local group = vim.api.nvim_create_augroup('lib.diff.tree.' .. src_buf, { clear = true })
  vim.b[src_buf].diff_tree_group = group

  local function close_tree()
    if vim.api.nvim_win_is_valid(tree_win) then
      vim.api.nvim_win_close(tree_win, true)
    end
    if vim.api.nvim_buf_is_loaded(src_buf) then
      vim.api.nvim_buf_clear_namespace(src_buf, TREE_NS, 0, -1)
      filepath_bar().set_hover(src_buf, nil)
      vim.b[src_buf].diff_tree_win = nil
      vim.b[src_buf].diff_tree_group = nil
    end
    pcall(vim.api.nvim_del_augroup_by_id, group)
  end

  -- <CR> jumps to the section; q closes the tree.
  vim.keymap.set('n', '<CR>', function()
    jump_to_row(tree_buf)
  end, { buffer = tree_buf, desc = 'Diff tree: jump to section' })
  vim.keymap.set('n', 'q', close_tree, { buffer = tree_buf, desc = 'Diff tree: close' })

  -- Hover (tree cursor moves): highlight + scroll the source.
  vim.api.nvim_create_autocmd('CursorMoved', {
    group = group,
    buffer = tree_buf,
    callback = function()
      M.tree_focus(tree_buf, tree_win)
    end,
  })

  -- Bidirectional: source cursor moves -> move tree cursor to the containing
  -- section (deepest first: hunk over block).
  vim.api.nvim_create_autocmd('CursorMoved', {
    group = group,
    buffer = src_buf,
    callback = function()
      if not vim.api.nvim_buf_is_loaded(tree_buf) or not vim.api.nvim_win_is_valid(tree_win) then
        pcall(vim.api.nvim_del_augroup_by_id, group)
        return
      end
      local idx = M.tree_row_containing(vim.b[tree_buf].diff_tree_rows, vim.fn.line('.') - 1)
      if idx then
        vim.api.nvim_win_set_cursor(tree_win, { idx, 0 })
      end
    end,
  })

  -- Leaving the tree clears the hover highlight.
  vim.api.nvim_create_autocmd('BufLeave', {
    group = group,
    buffer = tree_buf,
    callback = function()
      if vim.api.nvim_buf_is_loaded(src_buf) then
        vim.api.nvim_buf_clear_namespace(src_buf, TREE_NS, 0, -1)
        filepath_bar().set_hover(src_buf, nil)
      end
    end,
  })

  -- Close the tree when the diff buffer is hidden/unloaded.
  vim.api.nvim_create_autocmd({ 'BufHidden', 'BufUnload' }, {
    group = group,
    buffer = src_buf,
    callback = close_tree,
  })

  -- Show the first row and highlight it.
  vim.api.nvim_win_set_cursor(tree_win, { 1, 0 })
  M.tree_focus(tree_buf, tree_win)
end

return M
