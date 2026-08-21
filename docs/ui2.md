# ui2 research notes

Findings from studying `vim._core.ui2` (Neovim 0.12, system nvim v0.12.4 and
the `release-0.12` dev build) while building the command-output buffer feature
(see `cmd-output.md`). ui2 is **experimental** (news.txt): "a redesign of the
core messages and commandline UI, which will replace the legacy message grid
in the TUI".

## What ui2 is

A presentation layer for messages + cmdline. Instead of drawing into the
legacy message grid, it renders into **four dedicated buffer/window pairs**
(`require('vim._core.ui2').enable(opts)`):

| sink | window | purpose |
|---|---|---|
| `cmd` | bottom floating window | cmdline, 'showcmd', 'showmode', 'ruler', messages (default target) |
| `msg` | floating, auto-hides after `msg.msg.timeout` (default 4000ms) | ephemeral messages for `cmdheight=0` |
| `pager` | floating, entered on demand | `:messages` via `g<`, spilled/expanded messages |
| `dialog` | floating | modal prompts / paging (`f`/`b`/`j`/`k`/`d`/`u`/`g`/`G`) |

Key mechanics (`ui2.lua`):

- `check_targets()` lazily creates each window/buffer with `relative='laststatus'`,
  `style='minimal'`, `focusable=false`, and per-sink zindex (`201 - i`).
- Each buffer gets `filetype` = the sink id (`cmd`/`msg`/`pager`/`dialog`),
  fired with window context — **the documented extension point** for local
  options: `vim.api.nvim_create_autocmd('FileType', { pattern = 'pager', ... })`.
- The pager maps `q` → `wincmd c`.
- `enable()` is a no-op when `#vim.api.nvim_list_uis() == 0` (headless without
  a UI client): "Don't prevent stdout messaging when no UIs are attached".

## Message routing: `msg.targets`

`enable({ msg = { targets = { [kind_or_trigger] = 'cmd'|'msg'|'pager' } } })`
routes messages by kind or trigger (`msg_show`'s `kind`/`trigger` params; the
full kind list is in `:h ui-event-msg_show`, including `shell_cmd`,
`shell_out`, `shell_err`, `shell_ret`, `search_cmd`, `wildlist`, ...).
`targets` can also be a plain string to set the default target.

**There is no "discard"/"ignore" target.** Routing `shell_out` to `pager`
works (verified) but re-opens the pager overlay; routing to `cmd` spills
`[+N]`. Suppressing ui2's rendering of a kind therefore requires wrapping
`require('vim._core.ui2.messages').msg_show` (what `cmd-output.lua` does).

Long messages are "collapsed" with a `[+x]` spill indicator instead of the
legacy "Press ENTER"; ENTER or `g<` shows them in the pager.

## How `:!` output flows (the crucial bit)

`:!cmd` output is **not** TTY passthrough in Neovim. `os_call_shell` runs the
command with pipes and `forward_output=true` (`os/shell.c`); `out_data_cb`
feeds the bytes through `msg_puts` (`msg_ext_append=true`, kind
`shell_out`/`shell_err`), which with `ext_messages` attached becomes
`msg_show` events. Verified empirically (headless `vim.ui_attach`):

```
{ "msg_show", "shell_cmd", { { 0, ":!man tmux\r\n", 0 } }, false, false, false, 1, "" }
{ "msg_show", "shell_out", { { 0, "TMUX(1) ...", 73 } }, false, false, true, 2, "" }
{ "msg_show", "shell_out", { { 0, "...", 73 } }, false, false, true, 3, "" }
```

Signature: `msg_show(kind, content, replace_last, history, append, id, trigger)`;
`content` is `[attr_id, text, hl_id]` tuples. `shell_ret` is emitted **only on
non-zero exit** ("shell returned N"). `:silent !` sets `msg_silent` and skips
`ext_messages` entirely (`message.c`), so silent commands emit nothing.

This is the primitive to hook for "capture command output": a second
`vim.ui_attach(ns, { ext_messages = true }, handler)` gets the same events
ui2 does.

## Event consumption: `ui_call_event` (src/nvim/ui.c)

All `vim.ui_attach` handlers are stored per-namespace and **every handler is
invoked for every event** — handlers cannot prevent each other from seeing an
event. Each handler's return value is truthy iff it "handled" the event;
`handled` only controls whether the event is **forwarded to UI clients**
(the TUI, embedded UIs): `if (!handled) UI_CALL(...)`.

Consequences:

- Returning `true` from your own handler suppresses the TUI's rendering of
  that event — but ui2's handler still renders it into its own windows.
- To fully take over a kind you must both consume it (return `true`) *and*
  stop ui2 from rendering it (the `msg_show` wrap above).
- `msg_show` for shell kinds is delivered in the "not fast" list
  (`ui.c`), i.e. normal (non-fast) Lua context.

## Why the pager feels like an overlay (and can't be a regular buffer)

- The pager is a floating window with `focusable=false` — `Ctrl-w` cannot move
  into/out of it, and `:bnext` while focused replaces the *floating window's*
  buffer rather than navigating the window layout. It is navigable with vim
  motions but not part of the normal window system.
- `set_pos('pager')` → `enter_pager()` makes it the current window, so routing
  output to it steals focus.
- It accumulates: every routed message appends to the same `[Pager]` buffer.

To get "a regular buffer", capture the events yourself and render into a
normal split (see `cmd-output.md`).

## Ghost buffers on `nvim_buf_set_name` (a real gotcha)

`nvim_buf_set_name` → `rename_buffer()` (`ex_cmds.c`) **deliberately creates a
new unlisted buffer holding the old name**, which becomes the window's
alternate file (`w_alt_fnum`). This is `:file newname` semantics — verified in
bare `nvim -u NONE` with plain names. Consequences:

- Reusing one buffer and renaming it per command leaks an unlisted empty
  "ghost" per rename (invisible in `:ls`, but `Ctrl-^` in that window jumps to
  the ghost).
- Fix used by `cmd-output.lua`: fresh buffer per command, never rename; the
  old buffer is wiped via `bufhidden=wipe` when it loses its last window.

## Other hooks and gotchas

- `FileType` on the sink ids is the supported customization point; setting
  `cmdheight=0` is "EXPERIMENTAL. Works better with ui2 enabled".
- ui2 attaches with `{ ext_messages = true, set_cmdheight = false }`.
- `g<` shows `:messages` history in the pager; message *history* is recorded
  in C regardless of routing, so consumed shell output still shows up there.
- ui2 reconfigures windows on `OptionSet cmdheight/laststatus` and
  `VimResized`/`TabEnter` (`check_targets` + `msg.set_pos`).
- `enable(false)` detaches and cleans up windows/buffers/autocmds.
- Patching `vim._core.ui2.messages` is surgery on a private module: guard with
  `pcall`, keep a reference to the original, and restore it on error so
  messages are never silently lost.

## Verification approach

- Headless `vim.ui_attach` + `pcall(vim.cmd, '!man tmux')` logs the raw
  events (no UI client needed; ui2's `enable()` early-return doesn't apply to
  a plain attach).
- End-to-end: `nvim --headless --embed -u NONE` driven by a minimal msgpack
  client (`nvim_ui_attach` is RPC-only, so `vim.api.nvim_ui_attach` is nil;
  use `vim.fn.uiattach` — also absent in `-u NONE` — or the RPC client). Use
  `-u NONE`: a bare `--embed` loads the user config, which pollutes results
  with plugin-created buffers (e.g. `miniicons://...`).
