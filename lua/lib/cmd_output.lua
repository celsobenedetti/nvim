--- Helpers for capturing `:!cmd` output into a native buffer.
---
--- The capture itself happens in after/plugin/cmd-output.lua, which listens to
--- ext_messages `msg_show` events (kinds `shell_cmd`/`shell_out`/`shell_err`).
--- This module holds the pure string/name logic so it can be unit-tested.
---
---@class LibCmdOutput
local M = {}

--- Strip the `:!` echo prefix and trailing newline from a `shell_cmd` message
--- to recover the command the user ran.
---
---@param shell_cmd string e.g. `":!man tmux\r\n"`
---@return string e.g. `"man tmux"`
M.parse_command = function(shell_cmd)
  return shell_cmd:gsub('^:%!', ''):gsub('[\r\n]+$', '')
end

--- Normalize captured raw output into buffer lines.
---
--- Shell output chunks arrive as raw bytes: lines may be terminated by `\n`,
--- `\r\n`, or a lone `\r` (e.g. progress-style overwrites). Trailing empty
--- lines are dropped so the buffer doesn't end on a blank line.
---
---@param raw string
---@return string[]
M.to_lines = function(raw)
  if raw == '' then
    return {}
  end
  local text = raw:gsub('\r\n', '\n'):gsub('\r', '\n')
  local lines = {}
  for line in (text .. '\n'):gmatch('(.-)\n') do
    lines[#lines + 1] = line
  end
  while #lines > 0 and lines[#lines] == '' do
    lines[#lines] = nil
  end
  return lines
end

--- Filetype heuristic from the command that produced the output.
---
--- `:!man tmux` output is the plain-text (non-tty) man page; giving the buffer
--- `filetype=man` activates the runtime man ftplugin (gj/gk, gO, q-to-close).
---
---@param command string e.g. `"man tmux"`
---@return string|nil
M.filetype_for = function(command)
  if command:match('^%s*man%s+') then
    return 'man'
  end
  return nil
end

return M
