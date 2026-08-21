--- @module 'command output -> native buffer'
---
--- Capture `:!cmd` stdout/stderr and render it into a real split buffer instead
--- of the transient ui2 pager overlay. With ext_messages attached (which ui2
--- requires), `:!` output arrives as `msg_show` events with kinds
--- `shell_cmd` (the echoed command), `shell_out`/`shell_err` (stdout/stderr
--- chunks). We consume those events and replay them into a regular listed
--- buffer in a normal window, so `:bnext`, `Ctrl-w`, `:ls` etc. all work.
---
--- Two pieces cooperate:
--- 1. Our own `vim.ui_attach` handler accumulates shell output and returns
---    `true`, so the TUI never renders it.
--- 2. ui2's message router is patched to skip `shell_out`/`shell_err`, so the
---    output doesn't also spill into the cmdline or jump to the pager.
---
--- The window is sticky (reused across commands, mirroring the sticky
--- terminal), but each command gets a fresh buffer: renaming a buffer in nvim
--- creates an unlisted "old name" ghost for the alternate file (see
--- rename_buffer() in ex_cmds.c), and fresh buffers avoid that entirely. The
--- previous buffer is wiped automatically via 'bufhidden'.
---
--- See docs/cmd-output.md.

local augroup = vim.api.nvim_create_augroup('celso_cmd_output', { clear = true })

local M = {
  ns = vim.api.nvim_create_namespace('nvim_cmd_output'),
  win = -1, -- the sticky split window, reused across commands
  state = nil, -- active capture: { cmd = string, raw = string }
}

--- Buffer height for a new split, as a fraction of the screen.
local HEIGHT_FRACTION = 0.45

--- Patch ui2's message router to skip shell output, which we render ourselves.
--- ui2 has no "discard" target ('cmd'|'msg'|'pager' only), so the router
--- function is wrapped. If ui2 is absent (e.g. unit tests) this is a no-op.
local function patch_ui2()
  local ok, messages = pcall(require, 'vim._core.ui2.messages')
  if not ok or not messages or not messages.msg_show then
    return
  end
  M.orig_msg_show = messages.msg_show
  messages.msg_show = function(kind, ...)
    if kind == 'shell_out' or kind == 'shell_err' then
      return
    end
    return M.orig_msg_show(kind, ...)
  end
end

--- Restore ui2's router if something goes wrong, so output is never lost.
local function unpatch_ui2()
  if M.orig_msg_show then
    local ok, messages = pcall(require, 'vim._core.ui2.messages')
    if ok and messages then
      messages.msg_show = M.orig_msg_show
    end
    M.orig_msg_show = nil
  end
end

--- Consume a `msg_show` event for shell output. Never throws: the handler
--- runs for every message nvim emits and must not error, otherwise nvim
--- unregisters it and output is lost.
---
---@param kind string
---@param content MsgContent
local function on_shell_msg(kind, content)
  local ok, err = pcall(function()
    local text = {}
    for _, chunk in ipairs(content) do
      text[#text + 1] = chunk[2]
    end
    text = table.concat(text)
    if kind == 'shell_cmd' then
      M.state = { cmd = lib.cmd_output.parse_command(text), raw = '' }
    elseif kind == 'shell_out' or kind == 'shell_err' then
      if not M.state then
        M.state = { cmd = '', raw = '' }
      end
      M.state.raw = M.state.raw .. text
    end
  end)
  if not ok then
    vim.notify('cmd-output: ' .. err, vim.log.levels.ERROR)
    unpatch_ui2()
  end
end

vim.ui_attach(M.ns, { ext_messages = true }, function(event, ...)
  if event ~= 'msg_show' then
    return
  end
  local kind = ...
  if kind ~= 'shell_cmd' and kind ~= 'shell_out' and kind ~= 'shell_err' then
    return
  end
  on_shell_msg(kind, select(2, ...))
  return true -- consume: the TUI must not render shell output either
end)

patch_ui2()

--- Options for a cmd-output buffer, set once at creation.
---@param buf integer
local function setup_buffer(buf)
  vim.bo[buf].buftype = 'nofile'
  vim.bo[buf].bufhidden = 'wipe' -- no lingering scratch buffers after close
  vim.bo[buf].swapfile = false
end

--- Write a finished capture into a fresh buffer in the sticky window,
--- opening a new split when needed.
---
---@param job { cmd: string, raw: string }
local function show_output(job)
  local lines = lib.cmd_output.to_lines(job.raw)
  if #lines == 0 then
    return
  end

  -- Reuse the sticky window only if it still shows a cmd-output buffer that
  -- the user hasn't edited; otherwise open a fresh split.
  local win = 0
  if vim.api.nvim_win_is_valid(M.win) and vim.api.nvim_win_get_tabpage(M.win) == vim.api.nvim_get_current_tabpage() then
    local wbuf = vim.api.nvim_win_get_buf(M.win)
    if vim.fn.bufname(wbuf):match('^%[cmd%]') and not vim.bo[wbuf].modified then
      win = M.win
    end
  end
  if win == 0 then
    vim.cmd('belowright split')
    win = vim.api.nvim_get_current_win()
    M.win = win
    local height = math.min(math.max(10, #lines + 2), math.floor(vim.o.lines * HEIGHT_FRACTION))
    vim.cmd('resize ' .. height)
  end

  -- Fresh buffer per command (see module comment about rename ghosts). The
  -- previous buffer loses its last window and is wiped via 'bufhidden'.
  local buf = vim.api.nvim_create_buf(true, false) -- listed: shows in :ls, :bnext
  vim.api.nvim_win_set_buf(win, buf)
  setup_buffer(buf)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_name(buf, '[cmd] ' .. job.cmd)
  vim.bo[buf].filetype = lib.cmd_output.filetype_for(job.cmd) or 'cmd-output'
  vim.keymap.set('n', 'q', function()
    vim.cmd('close') -- bufhidden=wipe cleans up the buffer
  end, { buffer = buf, silent = true, desc = 'Close command output' })
  vim.api.nvim_win_set_cursor(win, { 1, 0 })
  vim.api.nvim_set_current_win(win)
end

--- Finalize the capture for a finished `:!` command. `ShellCmdPost` fires once
--- per `:!` (also for `:silent !`, which emits no messages and is skipped).
vim.api.nvim_create_autocmd('ShellCmdPost', {
  group = augroup,
  callback = function()
    local job = M.state
    M.state = nil
    if not job or job.raw == '' then
      return
    end
    vim.schedule(function()
      local ok, err = pcall(show_output, job)
      if not ok then
        vim.notify('cmd-output: ' .. err, vim.log.levels.ERROR)
        unpatch_ui2()
      end
    end)
  end,
  desc = 'cmd-output: open captured :! output in a native buffer',
})
