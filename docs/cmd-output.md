# Command output in a native buffer (`:!cmd` → split)

`after/plugin/cmd-output.lua` makes `:!man tmux` open the output in a **real
buffer in a normal window** instead of the transient ui2 pager overlay. The
buffer is listed (`:ls`, `:bnext`, `Ctrl-w` all work), named `[cmd] man tmux`,
gets `filetype=man` for man pages, and is reused across commands via a sticky
window (mirroring the sticky terminal).

## How `:!` output actually flows

`:!cmd` output is not TTY passthrough in Neovim — it is piped and replayed
through the message system (`os_call_shell` → `out_data_cb` → `msg_puts`). With
`ext_messages` attached (which ui2 requires), it arrives as `msg_show` events:

| kind | payload | when |
|---|---|---|
| `shell_cmd` | `:!man tmux\r\n` echo | command starts |
| `shell_out` | stdout chunks (`append=true`) | streaming |
| `shell_err` | stderr chunks | streaming |
| `shell_ret` | `shell returned N` | only on **non-zero** exit |

The output chunks are raw bytes; `lib.cmd_output.to_lines` normalizes `\r\n`,
lone `\r`, and trailing blank lines. `ShellCmdPost` marks command completion.

## Two cooperating pieces

1. **Own `vim.ui_attach` handler** (`ext_messages`) accumulates `shell_cmd` /
   `shell_out` / `shell_err` and returns `true`, so the TUI never renders the
   output (a `ui_attach` callback returning truthy marks the event handled; see
   `ui_call_event()` in `src/nvim/ui.c`).
2. **ui2's message router is patched** to skip `shell_out`/`shell_err`. ui2 has
   no "discard" target (`'cmd'|'msg'|'pager'` only — routing to the pager
   opens the floating overlay, routing to `cmd` spills `[+N]`), so
   `require('vim._core.ui2.messages').msg_show` is wrapped. This is surgery on
   a private module; it is guarded by `pcall` and restored (`unpatch_ui2`) if
   anything in the pipeline errors, so output is never silently lost.

The `:!cmd` echo (`shell_cmd`) is *not* skipped — it still shows in ui2's
cmdline so you see what ran.

## Design notes

- **Native window, not floating.** ui2's pager is a `focusable=false` floating
  window, which breaks standard navigation (`Ctrl-w` can't leave it, `:bnext`
  replaces the floating window's buffer). This feature opens a `belowright
  split` — a normal window.
- **Fresh buffer per command + sticky window.** Renaming a buffer in nvim
  creates an unlisted "old name" ghost buffer for the alternate file
  (`rename_buffer()` in `src/nvim/ex_cmds.c` deliberately does this), so
  reusing one buffer and renaming it would leak a ghost per command. Instead
  each command gets a fresh buffer; the previous one is wiped automatically
  via `bufhidden=wipe` when it loses its last window.
- **Sticky window reuse** only when the window still shows a cmd-output buffer
  the user hasn't edited; otherwise a fresh split opens (so a repurposed
  window is never hijacked).
- **`q` closes** the buffer (buffer-local), like help/quickfix scratch buffers.

## Interaction with `:silent !`

`:silent !cmd` sets `msg_silent`, and `msg_puts` skips `ext_messages` when
silent (`message.c`), so no events are captured and nothing opens — explicit
silencing is respected.

## Verification

- Unit tests: `tests/lib/test_cmd_output.lua` (`make test`) for
  `parse_command` / `to_lines` / `filetype_for`.
- Integration: `nvim --headless --embed -u NONE` with a msgpack UI client,
  asserting the `[cmd]` buffer is listed, non-floating, gets `filetype=man`,
  that ui2's cmdline contains only the echo (patch active), the pager never
  becomes the current window, and the UI receives zero `msg_show` redraws for
  shell output (consumed). See the commit message for the ghost-buffer
  investigation (`nvim_buf_set_name` → `rename_buffer`).
