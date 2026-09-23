--- @module 'pi' terminal integration for the pi coding agent
--- Everything that is specific to pi terminals lives here: recognising them
--- (any terminal running pi, not just the sticky `<leader>pi` buffer registered
--- by after/plugin/agents.lua), tailing their output in unfocused windows, and
--- keeping them out of insert mode. The reusable terminal/process primitives it
--- builds on are in lua/lib/term.lua.

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

-- pi renders its own input box; nvim's insert mode on terminal enter fights it.
table.insert(lib.term.startinsert_exemptions, is_running)

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

--- Watch `buf` for output, once. on_lines fires on terminal output even for
--- non-current buffers (refresh_screen -> changed_lines with do_buf_event);
--- BufModifiedSet never fires for terminal buffers and WinScrolled fires only
--- after a scroll, too late to drive one.
local function attach_follow(buf)
  if vim.b[buf].pi_follow_attached then
    return
  end
  vim.b[buf].pi_follow_attached = true
  vim.api.nvim_buf_attach(buf, false, {
    on_lines = function()
      follow_output(buf)
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
      attach_follow(buf)
    end
  end,
})
