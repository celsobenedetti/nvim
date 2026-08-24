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
local QUERY =
  vim.treesitter.query.parse('diff', '(block (command (filename) @file) (new_file (filename) @new)?) @block')

-- `query.captures` is an id -> name list; build the name -> id map for
-- `iter_matches` results.
local CAPTURE_IDS = {}
for id, name in ipairs(QUERY.captures) do
  CAPTURE_IDS[name] = id
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

---Collect quickfix items from a fugitive patch buffer: one entry per
---treesitter `block`, `lnum` = the block's header line, `text` = the new
---path. Uniform across text hunks, new files, binary sections, and renames.
---@param bufnr number
---@return table[] items quickfix items {bufnr, lnum, text}
M.parse_items = function(bufnr)
  local tree = vim.treesitter.get_parser(bufnr):parse()[1]
  local block_cap = CAPTURE_IDS.block
  local file_cap = CAPTURE_IDS.file
  local new_cap = CAPTURE_IDS.new
  local items = {}
  for _, match in QUERY:iter_matches(tree:root(), bufnr, 0, -1) do
    local block = match[block_cap] and match[block_cap][1]
    if block then
      -- `+++ b/x` when present (cleanest); otherwise the last command filename
      local name_node = (match[new_cap] and match[new_cap][1]) or (match[file_cap] and match[file_cap][1])
      local text = name_node and new_path(name_node, bufnr) or ''
      items[#items + 1] = { bufnr = bufnr, lnum = block:range() + 1, text = text }
    end
  end
  return items
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
---@param args string[]|string 0, 1, or 2 revision arguments. Also accepts
---the legacy call `open(rev1, rev2)` (two strings) — the pre-0913e74 `:Diff`
---command in after/plugin/git.lua called it that way, and a running nvim
---session registered before the fix still does (the lib itself loads
---lazily from disk, so the old command pairs with the new module).
M.open = function(args, ...)
  if type(args) ~= 'table' then
    args = { args, ... }
  end
  local n = #args
  local cmd, title, qf_title
  if n == 0 then
    cmd = 'tab Git diff'
    title = 'git diff'
    qf_title = 'Diff (working tree)'
  elseif n == 1 then
    cmd = 'tab Git show ' .. args[1]
    title = 'git show ' .. args[1]
    qf_title = 'Diff ' .. args[1]
  else
    cmd = 'tab Git diff -p ' .. args[1] .. ' ' .. args[2]
    title = 'git diff -p ' .. args[1] .. ' ' .. args[2]
    qf_title = 'Diff ' .. args[1] .. '..' .. args[2]
  end

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
    vim.fn.setqflist({}, ' ', { title = qf_title, items = items })
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

return M
