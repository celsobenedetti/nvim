--- @module 'pi' terminal integration for the pi coding agent
--- Everything that is specific to pi terminals lives here: recognising them
--- (any terminal running pi, not just the sticky `<leader>pi` buffer registered
--- by after/plugin/agents.lua), tailing their output in unfocused windows,
--- holding their viewport in place across a resize, and entering them in insert
--- mode only while their output is tailed. The reusable terminal/process
--- primitives it builds on are in lua/lib/term.lua.

--- How deep into the terminal job's process tree to look for pi. `:term pi`
--- makes pi the job process itself; `pi` typed into a shell terminal sits one
--- level below the shell; a wrapper (`mise exec`, `npx`) adds one more.
local SEARCH_DEPTH = 2

--- How long a detection result is reused for a buffer (ms). Detection walks
--- /proc, and `is_running` is called from the winbar's `%!` expression, which is
--- re-evaluated on every redraw, and from the follow handler below on every
--- batch of output — so the answer is cached rather than rescanned each time.
--- The TTL doubles as how long the answer may lag pi starting or exiting inside
--- a shell terminal.
local CACHE_MS = 500
local cache = {} -- bufnr -> { at = ms, value = boolean }

--- Is a pi instance running in this terminal buffer? True for the `<leader>pi`
--- agent terminal, and equally for a pi started by hand in any other terminal
--- buffer (`:term pi`, or typed into a shell terminal).
---@param buffer integer?
---@return boolean
local function is_running(buffer)
  if not buffer then
    buffer = vim.api.nvim_get_current_buf()
  end
  if not lib.term.is_term(buffer) then
    return false
  end
  -- The job command settles a `:term pi` from TermOpen onwards, where the
  -- process tree still reports the shell that is about to exec pi (measured:
  -- `bash` at TermOpen, `pi` ~50ms later). Without it the TermOpen startinsert
  -- would slip through on the agent terminal.
  local cmd = lib.term.job_command(buffer)
  local exe = cmd and cmd:match('^%s*(%S+)')
  if exe and vim.fs.basename(exe) == 'pi' then
    return true
  end

  local now = vim.uv.now()
  local cached = cache[buffer]
  if cached and now - cached.at < CACHE_MS then
    return cached.value
  end
  local value = lib.term.job_runs_process(buffer, 'pi', SEARCH_DEPTH)
  cache[buffer] = { at = now, value = value }
  return value
end

-- Read by after/plugin/winbar.lua (terminal labels) and the autocmds below.
state.pi = { is_running = is_running }

--- @module 'clone session: open a sibling pi terminal cloned from this one's
--- session'
--- Mirrors what pi's own `/clone` command does (copy the active branch into a
--- new session), but from outside: `pi --fork` makes the same copy before pi
--- starts. The session file to fork is preferred from the registry the pi
--- `session-pid` extension publishes (`<agent-dir>/instances/<pid>.json`, see
--- published_session below), which is exact. Without that extension pi's session
--- files are otherwise unaddressable from its pid (no lockfile, no open fd once
--- idle, no env var on the process itself, only on its own tool-call children),
--- so fall back to matching the session file's creation timestamp against the
--- pi process's own start time: a fresh `pi` creates its session file
--- (SessionManager.create, written synchronously before the TUI renders) within
--- a second of exec, and the filename records that instant to the millisecond.
--- Picking the session whose name is closest to the pid's start time -- rather
--- than the directory's most recently modified file -- also disambiguates two
--- pi terminals open on the same project.

--- Clock ticks per second (man 7 time, `sysconf(_SC_CLK_TCK)`), needed to read
--- /proc/<pid>/stat's starttime field. Virtually always 100 on Linux, but read
--- rather than assumed.
local CLK_TCK = tonumber(vim.fn.system('getconf CLK_TCK')) or 100

--- Boot time (seconds since epoch), the base that a process starttime (also
--- from boot) is measured against. Fixed for the uptime of the machine, so
--- read once rather than per lookup.
local BOOT_EPOCH = tonumber(vim.fn.system('grep -o "^btime [0-9]*" /proc/stat'):match('(%d+)'))

--- `os.time` reads a date table as local time with no way to ask for UTC, so
--- converting the UTC timestamp pi's session filenames carry needs this
--- correction: the gap between what `os.time` would say for the current
--- instant read as local and read as UTC. Recomputed as needed would also
--- work (DST can move it mid-session) but the gap is in whole hours and a
--- stale value only matters for the hour of a DST transition itself.
local LOCAL_MINUS_UTC = os.time() - os.time(os.date('!*t'))

--- Seconds a pi process may take from exec to writing its session file --
--- settings and extension discovery before `createSessionManager` runs in
--- main.ts -- before a session file is no longer considered this pid's own.
local SESSION_CREATE_SLACK_SECS = 10

--- Default session directory pi computes for `cwd`, replicating
--- getDefaultSessionDirPath in @earendil-works/pi-coding-agent's
--- session-manager.ts: `/a/b` -> `~/.pi/agent/sessions/--a-b--`.
---@param cwd string
---@return string
local function session_dir(cwd)
  local safe = cwd:gsub('^[/\\]', ''):gsub('[/\\:]', '-')
  return vim.fs.normalize('~/.pi/agent/sessions/--' .. safe .. '--')
end

--- Working directory a terminal buffer's job was started in, nil for a
--- non-terminal buffer. Terminal buffers are named `term://{cwd}//{pid}:{cmd}`,
--- with `{cwd}` abbreviated under the home directory (`~/notes`), which
--- `vim.fs.normalize` expands back out to match pi's own resolved paths.
---@param buffer integer
---@return string?
local function term_cwd(buffer)
  local cwd = vim.api.nvim_buf_get_name(buffer):match('^term://(.-)//')
  return cwd and vim.fs.normalize(cwd)
end

--- When `pid` was exec'd, as seconds since epoch; nil if `/proc/<pid>` is
--- already gone.
---@param pid integer
---@return number?
local function proc_start_epoch(pid)
  local ok, lines = pcall(vim.fn.readfile, '/proc/' .. pid .. '/stat')
  if not ok or not lines[1] then
    return nil
  end
  -- comm (field 2) is parenthesised and may itself contain spaces or parens,
  -- so the fields before it are unsafe to split on space; only what follows
  -- its closing paren is. starttime is field 22 overall, so field 20 counting
  -- from state (field 3) as 1.
  local after = lines[1]:match('%)%s*(.*)')
  local starttime_ticks = after and tonumber(vim.split(after, ' ')[20])
  if not starttime_ticks then
    return nil
  end
  return BOOT_EPOCH + starttime_ticks / CLK_TCK
end

--- Instant a pi session filename
--- (`2026-10-12T02-27-14-918Z_<uuid>.jsonl`) records, as seconds since epoch;
--- nil if `path` isn't named like one.
---@param path string
---@return number?
local function filename_epoch(path)
  local y, mo, d, h, mi, s, ms = vim.fs.basename(path):match('^(%d+)-(%d+)-(%d+)T(%d+)-(%d+)-(%d+)-(%d+)Z_')
  if not y then
    return nil
  end
  local utc = {
    year = tonumber(y),
    month = tonumber(mo),
    day = tonumber(d),
    hour = tonumber(h),
    min = tonumber(mi),
    sec = tonumber(s),
  }
  return os.time(utc) + LOCAL_MINUS_UTC + tonumber(ms) / 1000
end

--- Session file for `cwd` whose creation instant lies closest after `pid`'s
--- start time, within `SESSION_CREATE_SLACK_SECS`; nil when none correlates (a
--- `--continue`d or `--resume`d session doesn't create a new file at startup,
--- so there is nothing here to tell it apart from any other session in `cwd`)
--- or `pid` could not be read. A guess here would silently fork the wrong
--- conversation, so the caller is left to fail loudly instead.
---@param cwd string
---@param pid integer?
---@return string?
local function session_for_pid(cwd, pid)
  local start_epoch = pid and proc_start_epoch(pid)
  if not start_epoch then
    return nil
  end
  local best, best_diff
  for _, file in ipairs(vim.fn.glob(session_dir(cwd) .. '/*.jsonl', false, true)) do
    local epoch = filename_epoch(file)
    if epoch and epoch >= start_epoch - 2 and epoch - start_epoch <= SESSION_CREATE_SLACK_SECS then
      local diff = math.abs(epoch - start_epoch)
      if not best_diff or diff < best_diff then
        best, best_diff = file, diff
      end
    end
  end
  return best
end

--- Session file the pi `session-pid` extension published for `pid`, nil when
--- the extension is not loaded, the file is missing, or it belongs to another
--- process (a recycled pid). The registry path is fixed by the extension.
---@param pid integer
---@return string?
local function published_session(pid)
  local agent_dir = vim.env.PI_CODING_AGENT_DIR or vim.fs.normalize('~/.pi/agent')
  local ok, lines = pcall(vim.fn.readfile, vim.fs.joinpath(agent_dir, 'instances', pid .. '.json'))
  if not ok or not lines[1] then
    return nil
  end
  local decoded, data = pcall(vim.json.decode, table.concat(lines, '\n'))
  if not decoded or type(data) ~= 'table' or data.pid ~= pid or type(data.sessionFile) ~= 'string' then
    return nil
  end
  return data.sessionFile
end

--- Resolve the session of the pi running in `buf`: the published registry when
--- the extension is present, else the filename/start-time correlation above.
--- nil when neither can name it (a `--continue`d session with the extension
--- absent creates no new file, so there is nothing to correlate).
---@param buf integer
---@return string?
local function resolve_session(buf)
  local pid = lib.term.find_process(buf, 'pi', SEARCH_DEPTH)
  if not pid then
    return nil
  end
  local published = published_session(pid)
  if published then
    return published
  end
  local cwd = term_cwd(buf)
  return cwd and session_for_pid(cwd, pid) or nil
end

state.pi.resolve_session = resolve_session

--- Clone the session of the pi terminal in `buf` into a new vertical split.
---@param buf integer
local function clone_session(buf)
  if not is_running(buf) then
    return
  end
  local session = resolve_session(buf)
  if not session then
    Snacks.notify.warn("Could not resolve this terminal's pi session; not cloning", { title = 'pi clone' })
    return
  end
  Snacks.notify.info('Cloning session ' .. vim.fs.basename(session), { title = 'pi clone' })
  vim.cmd('vsplit')
  vim.cmd.term('pi --fork ' .. vim.fn.shellescape(session))
end

vim.api.nvim_create_user_command('PiFork', function()
  clone_session(vim.api.nvim_get_current_buf())
end, { desc = 'pi: clone this terminal session into a new vertical split' })

vim.keymap.set('n', '<leader>pc', function()
  clone_session(vim.api.nvim_get_current_buf())
end, { desc = 'pi: clone session into a new vertical split' })

--- Is the current window's cursor at the end of `buffer`'s output? The same
--- tolerance the follow flag uses (was_following): pi parks its cursor at its
--- input box a few lines above the end, so an exact last-line test would refuse
--- insert mode on the common "switch away from an idle pi, switch back" path.
---@param buffer integer
---@return boolean
local function at_bottom(buffer)
  local win = vim.api.nvim_get_current_win()
  return lib.term.was_following(
    vim.api.nvim_win_get_cursor(win)[1],
    vim.api.nvim_buf_line_count(buffer),
    vim.fn.mode()
  )
end

-- pi renders its own input box; nvim's insert mode on terminal enter fights it
-- when the window was scrolled up to read history: entering terminal mode pins
-- the cursor to pi's own and scrolls to the end (terminal_check_cursor), losing
-- the reading position. Enter a pi terminal in insert mode only while its output
-- is tailed -- cursor near the end -- and stay in normal mode otherwise.
table.insert(lib.term.startinsert_exemptions, function(buffer)
  return is_running(buffer) and not at_bottom(buffer)
end)

--- @module 'terminal follow: tail pi output in unfocused windows'
--- Neovim only keeps an unfocused terminal window scrolled to the newest output
--- while that window's cursor sits exactly on the last buffer line
--- (adjust_topline_cursor in terminal.c). TUIs like pi park their cursor a few
--- lines above the end (input box), so the built-in tailing never engages after
--- leaving the window. Remember whether the window was following when the user
--- left; on new output, pin its cursor back to the end. See
--- docs/terminal-follow.md.
local augroup = vim.api.nvim_create_augroup('custom-pi', {})
local following_windows = {} -- winid -> boolean

-- Coalesce per-buffer scroll work: on_lines fires per changed_lines call, which
-- the terminal refresh path emits per scrollback line. Schedule once per event-
-- loop batch instead of running on every callback.
local pending_follow = {} -- buf -> true

local function follow_output(buf)
  if pending_follow[buf] then
    return
  end
  pending_follow[buf] = true
  vim.schedule(function()
    pending_follow[buf] = nil
    -- Pin only terminals actually running pi: every terminal left while tailing
    -- is attached (pi may be started in a shell terminal later), and the pi that
    -- justified the attach may since have exited. is_running caches its /proc
    -- walk, so this is a table lookup on all but the first call per CACHE_MS.
    if not is_running(buf) then
      return
    end
    local line_count = vim.api.nvim_buf_line_count(buf)
    local current_win = vim.api.nvim_get_current_win()
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      if
        win ~= current_win
        and vim.api.nvim_win_get_buf(win) == buf
        and following_windows[win]
        -- built-in follow already keeps a caught-up window at the end
        and vim.api.nvim_win_get_cursor(win)[1] < line_count
      then
        vim.api.nvim_win_set_cursor(win, { line_count, 0 })
      end
    end
  end)
end

--- Re-apply a held resize anchor, reporting whether there was one. Defined in
--- the resize-anchor section below but needed by the output watcher here, which
--- both consumers share.
---@type fun(buffer: integer): boolean
local hold_anchor

--- Watch `buf` for output, once. on_lines fires on terminal output even for
--- non-current buffers (refresh_screen -> changed_lines with do_buf_event);
--- BufModifiedSet never fires for terminal buffers and WinScrolled fires only
--- after a scroll, too late to drive one.
local function attach_output(buf)
  if vim.b[buf].pi_follow_attached then
    return
  end
  vim.b[buf].pi_follow_attached = true
  vim.api.nvim_buf_attach(buf, false, {
    on_lines = function()
      -- A resize hold owns the viewport for as long as it lasts: it is the more
      -- specific intent, and pinning to the last line would overwrite the
      -- anchor a few lines above it. Tailing resumes on the next output after
      -- the hold is released.
      if not hold_anchor(buf) then
        follow_output(buf)
      end
    end,
  })
end

vim.api.nvim_create_autocmd('WinLeave', {
  desc = 'pi: remember whether a terminal window was tailing output',
  group = augroup,
  callback = function()
    local win = vim.api.nvim_get_current_win()
    local buf = vim.api.nvim_win_get_buf(win)
    if not lib.term.is_term(buf) then
      return
    end
    local cursor = vim.api.nvim_win_get_cursor(win)
    following_windows[win] = lib.term.was_following(cursor[1], vim.api.nvim_buf_line_count(buf), vim.fn.mode())
    -- Attach lazily, here rather than at TermOpen: a terminal only needs
    -- watching once it is left while tailing, and by then pi (which may have
    -- been started long after TermOpen) can be detected.
    if following_windows[win] then
      attach_output(buf)
    end
  end,
})

--- @module 'resize anchor: hold the viewport across pi's resize redraw'
--- pi redraws by clearing the screen *and the scrollback* — `\x1b[2J\x1b[H\x1b[3J`,
--- `fullRender(true)` in its tui-main-screen.ts — whenever the terminal's width
--- or height changes, then reprinting its whole transcript. Neovim's
--- `term_sb_clear` (terminal.c) frees the scrollback lines, so the buffer
--- collapses to the window height and `adjust_topline_cursor` clamps every
--- window's cursor into what survives; the reprint then regrows the buffer
--- *below* a cursor now stranded near the top. Snapshot how far each window sat
--- from the end before pi can react, and hold it there until the reprint
--- settles. See docs/pi-resize.md.

--- Poll interval for noticing that the reprint has stopped. This times only the
--- *release* of a hold: the anchored position is re-applied from the output
--- watcher, so no interval here gates when the viewport is right.
local SETTLE_MS = 120

--- How long pi has to answer the resize before the hold is abandoned without
--- touching anything. pi answers a SIGWINCH in tens of milliseconds; output
--- that only turns up later is a reply streaming in, not the redraw, and
--- moving the viewport on the strength of it would disturb a cursor that
--- nothing had disturbed. Reached whenever a resize leaves pi's character grid
--- unchanged, so it redraws nothing.
local REDRAW_GRACE_MS = 500

--- Stop holding this long after the resize even if the reprint never goes
--- quiet, as when a reply is streaming in: a hold outliving the redraw it was
--- taken for would fight the user's own scrolling.
local SETTLE_DEADLINE_MS = 2000

--- buf -> hold, while one is in force. `from_end` is the distance the window's
--- cursor sat above the last buffer line when the resize arrived.
---@type table<integer, { anchors: table<integer, integer>, changed: boolean, pending: boolean }>
local held = {}

--- Put every anchored window of `buf` back its recorded distance from the end
--- of the buffer. Exact for the common case of sitting at pi's input box;
--- approximate when the new width rewraps the transcript into a different
--- number of lines, which is the best available — the content the old position
--- pointed at no longer exists in the same shape.
---@param buf integer
local function apply_anchor(buf)
  local hold = held[buf]
  if not hold or not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  local line_count = vim.api.nvim_buf_line_count(buf)
  local current_win = vim.api.nvim_get_current_win()
  local in_terminal_mode = vim.fn.mode() == 't'
  for win, from_end in pairs(hold.anchors) do
    if
      vim.api.nvim_win_is_valid(win)
      and vim.api.nvim_win_get_buf(win) == buf
      -- nvim already pins the focused terminal-mode window to pi's own cursor
      -- (terminal_check_cursor); placing it anywhere else only fights that.
      and not (win == current_win and in_terminal_mode)
    then
      vim.api.nvim_win_set_cursor(win, { math.max(1, line_count - from_end), 0 })
    end
  end
end

--- Re-apply the hold on a batch of terminal output, so the anchored position is
--- restored in the same event-loop iteration that disturbed it and no frame is
--- ever drawn with the cursor where nvim's clamp left it. Reports whether a
--- hold is in force, which is what gives it precedence over tailing.
---
--- Scheduled, not run inline from `on_lines`: `refresh_terminal` (terminal.c)
--- runs `refresh_scrollback` and `refresh_screen` — which is where the buffer
--- update callbacks fire — and only *then* `adjust_topline_cursor`, so an
--- inline write would be clamped in its turn. A scheduled one lands after the
--- clamp and still before `update_screen` draws anything. Scheduling also
--- coalesces: `on_lines` fires once per scrollback line, and one re-apply per
--- event-loop batch is enough.
---@param buf integer
---@return boolean held
function hold_anchor(buf)
  local hold = held[buf]
  if not hold then
    return false
  end
  if not hold.pending then
    hold.changed, hold.pending = true, true
    vim.schedule(function()
      hold.pending = false
      apply_anchor(buf)
    end)
  end
  return true
end

--- Release the hold once pi has redrawn and the reprint has stopped growing the
--- buffer, or at the deadline.
---@param buf integer
---@param count integer buffer line count when the hold was taken
local function release_when_settled(buf, count)
  local started = vim.uv.now()
  local deadline = started + SETTLE_DEADLINE_MS
  local last_count = count
  local function poll()
    local hold = held[buf]
    if not hold or not vim.api.nvim_buf_is_valid(buf) then
      held[buf] = nil
      return
    end
    -- pi has not answered. `changed` is the only usable signal: a resize that
    -- does not rewrap reprints to exactly the same line count, so the count
    -- cannot tell "finished" from "never started".
    if not hold.changed then
      if vim.uv.now() - started >= REDRAW_GRACE_MS then
        held[buf] = nil -- nothing was disturbed, so there is nothing to repair
        return
      end
      return vim.defer_fn(poll, SETTLE_MS)
    end
    local line_count = vim.api.nvim_buf_line_count(buf)
    if line_count ~= last_count and vim.uv.now() < deadline then
      last_count = line_count
      return vim.defer_fn(poll, SETTLE_MS)
    end
    -- The last word, so the released position cannot be a stale one: a re-apply
    -- scheduled by the final batch of output would no-op if this cleared `held`
    -- before it ran.
    apply_anchor(buf)
    held[buf] = nil
  end
  vim.defer_fn(poll, SETTLE_MS)
end

--- Record where the resized windows showing `buf` sit, if `buf` is a pi
--- terminal not already holding — a resize mid-hold (dragging a split) must
--- keep the original anchor, not re-read the already-clamped cursors.
---@param buf integer
---@param resized table<integer, true>? window ids that changed size, nil for all
local function anchor_windows(buf, resized)
  if held[buf] or not is_running(buf) then
    return
  end
  local count = vim.api.nvim_buf_line_count(buf)
  local anchors = {}
  for _, win in ipairs(vim.fn.win_findbuf(buf)) do
    if not resized or resized[win] then
      anchors[win] = count - vim.api.nvim_win_get_cursor(win)[1]
    end
  end
  if next(anchors) == nil then
    return
  end
  held[buf] = { anchors = anchors, changed = false, pending = false }
  -- The resize autocmd runs before pi has even been signalled, so attaching
  -- here is still in time to catch the first line of its redraw.
  attach_output(buf)
  release_when_settled(buf, count)
end

vim.api.nvim_create_autocmd({ 'VimResized', 'WinResized' }, {
  desc = "pi: hold terminal windows in place across pi's resize redraw",
  group = augroup,
  callback = function(ev)
    -- Only windows that actually changed size. `WinResized` fires for any
    -- layout change in the tab page — opening a split elsewhere, closing one —
    -- and anchoring a pi window that kept its size would take a hold pi has no
    -- reason to answer, then drag that window to the recorded offset on
    -- whatever output turned up next. `v:event.windows` names the ones that
    -- moved; `VimResized` means all of them.
    local wins, resized = vim.api.nvim_list_wins(), nil
    if ev.event == 'WinResized' then
      wins, resized = vim.v.event.windows or {}, {}
      for _, win in ipairs(wins) do
        resized[win] = true
      end
    end
    -- Synchronous, so this runs before nvim returns to the event loop and can
    -- read pi's reaction: the cursors sampled here are still the pre-redraw
    -- ones. `held` makes the repeat visit harmless when both events fire for
    -- one resize, and when a buffer is shown in several windows.
    for _, win in ipairs(wins) do
      if vim.api.nvim_win_is_valid(win) then
        anchor_windows(vim.api.nvim_win_get_buf(win), resized)
      end
    end
  end,
})
