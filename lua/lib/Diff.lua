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

---Argument normalization shared by M.open / M.open_qf.
---@param args string[]|string 0, 1, or 2 revision arguments; a single
---argument containing `..` (e.g. `dev..HEAD`, `dev...HEAD`) is treated as
---a diff range rather than a `git show` rev. Also accepts the legacy call
---`open(rev1, rev2)` (two strings) — the pre-0913e74 `:Diff`
---command in after/plugin/git.lua called it that way, and a running nvim
---session registered before the fix still does (the lib itself loads
---lazily from disk, so the old command pairs with the new module).
---@return string[]
local function normalize_args(args, ...)
  if type(args) ~= 'table' then
    return { args, ... }
  end
  return args
end

---Open the fugitive patch for `args` in a dedicated tab and wait for its job.
---Completion is tracked through fugitive's own async job
---(fugitive#Result/fugitive#Wait) — the buffer is empty until the job
---finishes, so the treesitter parse must wait for it (docs/diff-emph.md
---gotcha #3).
---@param args string[]
---@return integer? bufnr the patch buffer, nil when `:Git` itself failed
---@return table? result fugitive's job result (exit_status, job)
---@return string? title `Diff <args>`, for the quickfix list and its winbar
local function patch_tab(args)
  local n = #args
  local git_args, title
  if n == 0 then
    git_args = 'diff'
    title = 'Diff (working tree)'
  elseif n == 1 then
    -- A single arg with `..` (two- or three-dot) is a range, not a rev:
    -- `git diff -p dev..HEAD` / `dev...HEAD`. Valid refnames never
    -- contain `..` (git check-ref-format), so the check is unambiguous.
    git_args = (args[1]:find('..', 1, true) and 'diff -p ' or 'show ') .. args[1]
    title = 'Diff ' .. args[1]
  else
    git_args = 'diff -p ' .. args[1] .. ' ' .. args[2]
    title = 'Diff ' .. args[1] .. '..' .. args[2]
  end

  lib.tab.set_next_name(config.icons.git.git .. 'git ' .. git_args)
  local ok, err = pcall(vim.cmd, 'tab Git ' .. git_args)
  if not ok then
    lib.tab.set_next_name(nil)
    vim.notify('Diff: ' .. tostring(err), vim.log.levels.ERROR)
    return nil, nil, nil
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
  return bufnr, result, title
end

---A patch with no per-file sections: still rendering (leave the tab alone),
---genuinely empty (close it again), or a git failure worth leaving on screen.
---@param result table fugitive's job result
---@param args string[]
local function report_empty(result, args)
  if result.exit_status == nil then
    -- Wait timed out (huge diff); leave the tab open for it to finish.
    vim.notify('Diff: diff still rendering', vim.log.levels.INFO)
  elseif result.exit_status == 0 then
    vim.cmd('tabclose')
    vim.notify(
      'Diff: no changes' .. (#args > 0 and (' between ' .. table.concat(args, ' ')) or ''),
      vim.log.levels.INFO
    )
  else
    vim.notify('Diff: git exited with ' .. result.exit_status .. '; see the error in the new tab', vim.log.levels.WARN)
  end
end

---`:Diff` — the patch in a dedicated tab with the DiffTree sidebar (per-file
---blocks and their hunks) open on the left and focused, so hovering a row
---previews the section (`docs/diff-tree.md`). M.open_qf is the older
---quickfix-of-files flavour, kept as `:DiffQf`.
---@param args string[]|string see normalize_args
M.open = function(args, ...)
  args = normalize_args(args, ...)
  local bufnr, result = patch_tab(args)
  if not bufnr then
    return
  end

  local ok, rows = pcall(M.tree_rows, bufnr)
  if not ok then
    vim.notify('Diff: treesitter diff parser unavailable: ' .. tostring(rows), vim.log.levels.WARN)
    return
  end

  if #rows > 0 then
    -- The patch window is current, so the tree attaches to it (and its own
    -- parse of the same, already-cached tree yields these rows again).
    M.open_tree()
    return
  end

  report_empty(result, args)
end

---`:DiffQf` — the patch in a dedicated tab with a quickfix list of the changed
---files below it (focused), one entry per `diff --git` block. Was `:Diff`
---until the tree became the default.
---@param args string[]|string see normalize_args
M.open_qf = function(args, ...)
  args = normalize_args(args, ...)
  local bufnr, result, qf_title = patch_tab(args)
  if not bufnr then
    return
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
    local args_text = #args > 0 and (' ' .. table.concat(args, ' ')) or ''
    M.record_winbar(vim.fn.getqflist({ id = 0 }).id, config.icons.git.git .. ' Diff' .. args_text)
    vim.cmd('botright copen')
    M.install_qf_jump()
    return
  end

  report_empty(result, args)
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
-- (CursorMoved) parks the section at the top of the diff window and unfolds
-- it; <CR> jumps there; the diff buffer's own cursor keeps the tree in sync
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

---New path of the per-file `block` the cursor sits in, for actions that
---operate on "the file I'm looking at" inside a patch buffer (the `ga`
---staging keymap in after/ftplugin/git.lua). Returns nil when the buffer has
---no `diff` parse tree, or the cursor is outside every block (e.g. on
---`:Git log -p` commit headers).
---@param bufnr? number defaults to the current buffer
---@return string?
M.cursor_block_path = function(bufnr)
  bufnr = (not bufnr or bufnr == 0) and vim.api.nvim_get_current_buf() or bufnr
  local ok, tree = pcall(function()
    return vim.treesitter.get_parser(bufnr):parse()[1]
  end)
  if not ok or not tree then
    return nil
  end

  local row = vim.fn.line('.') - 1 -- 0-based cursor row
  -- Last block first: a block's end position is the start of the next block's
  -- first line (end_col 0), so both would match on that row.
  local blocks = collect_nodes(tree:root(), 'block')
  for i = #blocks, 1, -1 do
    local start_row, _, end_row = blocks[i]:range()
    if row >= start_row and row <= end_row then
      local path = block_path(blocks[i], bufnr)
      return path ~= '' and path or nil
    end
  end
  return nil
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
---their block (`text` = the `@@` line, plus their block's `path`, so
---file-scoped actions work from a hunk row). `lnum` is the 1-based jump target
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
            -- Its block's path: file actions (`ga`) work from a hunk row too.
            path = path,
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

---Refresh nvim-treesitter-context's sticky context for a window we are *not*
---focused in — the diff window, while the cursor lives in the tree.
---
---The plugin only ever updates the current window (its CursorMoved /
---WinScrolled handler reads `nvim_get_current_win()`, and `WinScrolled` is not
---one of its multiwindow events), so a hover would leave the diff window's
---context showing whatever section was last focused. Its two internals are
---fully winid-parameterized, so drive them for that window directly.
---
---`multiwindow = true` (lua/plugins/treesitter.lua) is what keeps the result
---alive: with it off, the plugin binds its close handler to `WinLeave`
---(entering the tree would close this context) and every update for the tree
---window garbage-collects the other windows' contexts.
---
---No-op when the plugin isn't installed (`-u NONE` in the tests), when the user
---turned it off with `:TSContextToggle`, and if its internals ever move.
---@param win integer
local function refresh_context(win)
  local ok, tsc = pcall(require, 'treesitter-context')
  if not ok or not tsc.enabled() then
    return
  end
  -- Private modules, so the whole hand-off is guarded: a rename upstream must
  -- degrade to "no context on hover", not throw on every CursorMoved.
  pcall(function()
    local ranges, lines = require('treesitter-context.context').get(win)
    local render = require('treesitter-context.render')
    if ranges and #ranges > 0 and lines then
      render.open(win, ranges, lines)
    else
      render.close(win)
    end
  end)
end

---The tree row under the tree cursor (`vim.b.diff_tree_rows` is 1:1 with the
---tree buffer's lines), or nil.
---@param tree_buf integer
---@return table? row
local function row_under_cursor(tree_buf)
  local rows = vim.b[tree_buf].diff_tree_rows
  return rows and rows[vim.fn.line('.')] or nil
end

---Window in this tabpage showing the tree's source diff buffer (never the
---tree window itself), plus that buffer. The window is cached on the tree
---buffer by open_tree; the scan covers it having been closed since.
---@param tree_buf integer
---@return integer? src_win
---@return integer? src_buf
local function tree_src_win(tree_buf)
  local src_buf = vim.b[tree_buf].diff_tree_src
  if not src_buf or not vim.api.nvim_buf_is_loaded(src_buf) then
    return nil, nil
  end
  local cached = vim.b[tree_buf].diff_tree_src_win
  if cached and vim.api.nvim_win_is_valid(cached) and vim.api.nvim_win_get_buf(cached) == src_buf then
    return cached, src_buf
  end
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.api.nvim_win_get_buf(win) == src_buf then
      return win, src_buf
    end
  end
  return nil, src_buf
end

---Move the diff buffer's cursor to the tree row under the cursor, reusing a
---window that already shows it (never the tree window itself).
local function jump_to_row(tree_buf)
  local r = row_under_cursor(tree_buf)
  local src_win = tree_src_win(tree_buf)
  if not r or not src_win then
    return
  end
  vim.api.nvim_set_current_win(src_win)
  vim.api.nvim_win_set_cursor(src_win, { r.lnum, 0 })
  vim.cmd.norm('zt')
end

---`ga` in the tree: stage the row's file through lib.git.add (the same flow
---as `ga` in a normal buffer or in the patch buffer itself). Hunk rows carry
---their block's path, so either row kind stages the whole file. Focus moves
---to the diff window first, so fugitive's interactive `Git add -p` split
---opens there rather than inside the 30-column sidebar. Exposed for the
---headless test.
---@param tree_buf integer
M.tree_stage = function(tree_buf)
  local r = row_under_cursor(tree_buf)
  if not r or not r.path or r.path == '' then
    return
  end
  local src_win = tree_src_win(tree_buf)
  if src_win then
    vim.api.nvim_set_current_win(src_win)
  end
  require('lib.git').add(r.path)
end

---Fold commands the tree forwards to the diff buffer, keyed by the mapping
---they are bound to. Two families:
---
--- * line-scoped (`za zA zc zC zo zO`) — act on the row's section. `close`
---   picks the direction, `toggle` derives it from the current state, `bang`
---   is `:foldopen!`/`:foldclose!` (recursive, so a file row also folds its
---   hunks' own folds).
--- * window-wide (`zR zM zr zm`) — only move the window's 'foldlevel', so
---   they are cursor-independent and can be forwarded verbatim (with a count:
---   `3zm`).
local TREE_FOLD_ACTIONS = {
  za = { toggle = true },
  zA = { toggle = true, bang = true },
  zc = { close = true },
  zC = { close = true, bang = true },
  zo = { close = false },
  zO = { close = false, bang = true },
  zR = { global = true },
  zM = { global = true },
  zr = { global = true },
  zm = { global = true },
}

---Run one of the tree's fold mappings (see TREE_FOLD_ACTIONS) against the diff
---buffer, then mirror the result onto the tree's own folds. The folds are the
---`diff` grammar's (folds.scm captures `block`/`hunks`/`hunk`;
---after/ftplugin/git.lua puts treesitter's foldexpr on patch windows).
---
---Line-scoped commands use the range form (`:{lnum}foldclose`), which acts on
---a line without moving the diff window's cursor — unlike `normal! zc`. A file
---row folds its whole `diff --git` block, a hunk row its `@@` section; only
---file rows have a fold to mirror in the tree (see M.tree_foldexpr), and
---closing theirs hides their hunk rows here too.
---
---Window-wide commands re-run in the tree window as well, so `zM` collapses
---the tree to one row per file and `zR` expands both again.
---
---Returns the new closed state for line-scoped commands (`true` = closed) —
---the headless test reads it — or nil for window-wide ones and when the row
---has no fold.
---@param tree_buf integer
---@param key string a key of TREE_FOLD_ACTIONS
---@return boolean?
M.tree_fold = function(tree_buf, key)
  local spec = TREE_FOLD_ACTIONS[key]
  local src_win = tree_src_win(tree_buf)
  if not spec or not src_win then
    return nil
  end

  if spec.global then
    local keys = (vim.v.count > 0 and vim.v.count or '') .. key
    vim.api.nvim_win_call(src_win, function()
      vim.cmd('normal! ' .. keys)
    end)
    -- Same command in the tree: its foldlevel tracks the diff's.
    vim.cmd('normal! ' .. keys)
    return nil
  end

  local r = row_under_cursor(tree_buf)
  if not r then
    return nil
  end

  local tree_lnum = vim.fn.line('.')
  local closed = vim.api.nvim_win_call(src_win, function()
    if vim.fn.foldlevel(r.lnum) == 0 then
      -- Nothing folds there at all (a binary/rename block, or folds turned
      -- off): worth saying, unlike a `zo` on an already-open fold.
      vim.notify('DiffTree: no fold at that section', vim.log.levels.INFO)
      return nil
    end
    -- foldclosed() reports the *innermost closed* fold's start line, so a hunk
    -- inside an already-closed block reads as closed and toggles that block
    -- open — exactly what `za` on the hunk's line would do.
    local close = spec.close
    if spec.toggle then
      close = vim.fn.foldclosed(r.lnum) == -1
    end
    -- Already open/closed in that direction is an E490 from :foldopen /
    -- :foldclose; a repeated press is a no-op, not something to report.
    pcall(vim.cmd, string.format('%d%s%s', r.lnum, close and 'foldclose' or 'foldopen', spec.bang and '!' or ''))
    return close
  end)

  if closed == nil then
    return nil
  end

  -- Mirror onto the tree (only blocks fold here, see M.tree_foldexpr).
  if r.kind == 'block' then
    pcall(vim.cmd, string.format('%d%s%s', tree_lnum, closed and 'foldclose' or 'foldopen', spec.bang and '!' or ''))
  end
  return closed
end

---Focus the section under the tree cursor in the diff window: open every fold
---inside it (`zO`, so a file row reveals all of its hunks) and park it at the
---top of the window (`zt`, which honours the window's 'scrolloff'). Focus
---stays in the tree, so hover still isn't a jump. A block row also lights up
---lib.diff_filepath's overlay bar on its hover palette — the header line's
---visible pixels belong to that extmark, whose virt_text chunks no second
---extmark can restyle; hunk rows get no highlight at all, the scroll is the
---feedback. Finally nvim-treesitter-context is refreshed for the diff window
---(refresh_context), so a hovered hunk keeps its `diff --git` header pinned
---above it. Exposed as M.tree_focus for the headless integration test
---(CursorMoved never fires under --headless).
M.tree_focus = function(tree_buf, tree_win)
  local row = vim.fn.line('.')
  local rows = vim.b[tree_buf].diff_tree_rows
  local r = rows and rows[row]
  local src_buf = vim.b[tree_buf].diff_tree_src
  if not r or not src_buf or not vim.api.nvim_buf_is_loaded(src_buf) then
    return
  end

  filepath_bar().set_hover(src_buf, r.kind == 'block' and r.lnum - 1 or nil)

  -- The diff window's cursor has to move to the section: nvim keeps a window's
  -- cursor on screen, so a topline that would scroll it out of view is simply
  -- undone — which is why setting topline alone (the previous reveal-if-off-
  -- screen scroll) did nothing for distant sections.
  local src_win = vim.b[tree_buf].diff_tree_src_win
  if not src_win or not vim.api.nvim_win_is_valid(src_win) then
    local wins = vim.fn.win_findbuf(src_buf)
    src_win = wins[1]
    vim.b[tree_buf].diff_tree_src_win = src_win
  end
  if src_win then
    local srow, _, erow, ecol = unpack(r.range)
    -- A node that ends at a line break reports the *next* row with column 0
    -- (block 1 of a two-file patch ends on block 2's `diff --git` row), which
    -- would unfold the neighbouring section too.
    local last = (ecol == 0 and erow > srow) and erow or erow + 1
    -- Cursor first, and from outside nvim_win_call: moving a non-current
    -- window's cursor fires no CursorMoved, so the source->tree sync autocmd
    -- can't loop back on it.
    vim.api.nvim_win_set_cursor(src_win, { r.lnum, 0 })
    vim.api.nvim_win_call(src_win, function()
      -- `zO` over the whole section, as the range form: `:{a},{b}foldopen!`
      -- opens every fold in the range, nested ones included, so a file row
      -- reveals its hunks too — plain `zO` would only open the folds that
      -- contain the cursor line, leaving the hunks below it closed. Nothing
      -- foldable in the range is an E490: a silent no-op here, unlike the
      -- explicit `zo` mapping, which reports it.
      pcall(vim.cmd, string.format('%d,%dfoldopen!', srow + 1, last))
      -- Then park the section on top, on every hover and not only when it is
      -- off-screen. 'scrolloff' keeps its usual margin of context above it —
      -- which is also the room nvim-treesitter-context's float needs, so its
      -- sticky lines land above the section instead of covering it.
      vim.cmd('normal! zt')
    end)
    -- After the scroll: the context is computed from the window's topline.
    refresh_context(src_win)
  end
end

---Toggle the diff tree sidebar for the current buffer: a left-side vertical
---split listing each per-file `block` (`<icon> <path> <summary>`) with its
---`hunk`s (`@@` lines) nested underneath. Focus (CursorMoved) parks the
---section at the top of the diff window and unfolds it; <CR> jumps there; the
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

  -- Buffer vars first: M.tree_foldexpr reads `diff_tree_rows`, and setting
  -- 'foldmethod' evaluates the foldexpr right away — with the rows still
  -- unset every line came back level 0 and the cached result never got
  -- invalidated (nothing edits this buffer afterwards), so no row folded.
  vim.b[tree_buf].diff_tree_rows = rows
  vim.b[tree_buf].diff_tree_src = src_buf
  vim.b[tree_buf].diff_tree_src_win = src_win
  vim.b[src_buf].diff_tree_win = tree_win

  vim.wo[tree_win].wrap = false
  vim.wo[tree_win].foldmethod = 'expr'
  vim.wo[tree_win].foldexpr = 'v:lua.lib.Diff.tree_foldexpr()'
  vim.wo[tree_win].foldlevel = 99

  local group = vim.api.nvim_create_augroup('lib.diff.tree.' .. src_buf, { clear = true })
  vim.b[src_buf].diff_tree_group = group

  local function close_tree()
    if vim.api.nvim_win_is_valid(tree_win) then
      vim.api.nvim_win_close(tree_win, true)
    end
    if vim.api.nvim_buf_is_loaded(src_buf) then
      filepath_bar().set_hover(src_buf, nil)
      vim.b[src_buf].diff_tree_win = nil
      vim.b[src_buf].diff_tree_group = nil
    end
    pcall(vim.api.nvim_del_augroup_by_id, group)
  end

  -- <CR> jumps to the section; q closes the tree; ga stages the row's file;
  -- the z fold commands fold the diff buffer (and mirror onto the tree).
  vim.keymap.set('n', '<CR>', function()
    jump_to_row(tree_buf)
  end, { buffer = tree_buf, desc = 'Diff tree: jump to section' })
  vim.keymap.set('n', 'q', close_tree, { buffer = tree_buf, desc = 'Diff tree: close' })
  vim.keymap.set('n', 'ga', function()
    M.tree_stage(tree_buf)
  end, { buffer = tree_buf, desc = "Diff tree: git add the row's file" })
  for key in pairs(TREE_FOLD_ACTIONS) do
    vim.keymap.set('n', key, function()
      M.tree_fold(tree_buf, key)
    end, { buffer = tree_buf, desc = 'Diff tree: ' .. key .. ' in the diff buffer' })
  end

  -- Hover (tree cursor moves): scroll + unfold the source section.
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

  -- Leaving the tree drops the hovered block's bar back to its normal palette.
  vim.api.nvim_create_autocmd('BufLeave', {
    group = group,
    buffer = tree_buf,
    callback = function()
      if vim.api.nvim_buf_is_loaded(src_buf) then
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

  -- Show the first row and focus its section.
  vim.api.nvim_win_set_cursor(tree_win, { 1, 0 })
  M.tree_focus(tree_buf, tree_win)
end

return M
