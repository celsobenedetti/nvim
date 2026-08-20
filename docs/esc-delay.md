# `<Esc>` delay in insert mode (`ttimeoutlen`)

Pressing `<Esc>` in insert mode felt delayed (~50ms). Root cause: Neovim's TUI
waits `ttimeoutlen` (default **50ms**) after the `<Esc>` byte to disambiguate
it from the start of a key-code sequence (e.g. `ESC[A` = Up arrow). Every
`<Esc>` press in insert mode costs exactly `ttimeoutlen`.

## Verified empirically (pty + RPC `mode()` poll)

| Config | `<Esc>` latency |
|---|---|
| default (`ttimeoutlen=50`) | **50.1 ms** |
| `ttimeoutlen = 10` | **10.3 ms** (imperceptible) |
| `ttimeoutlen = 0` / `ttimeout off` | **0.1 ms** |

The insert-mode `<esc>` expr mapping in `after/plugin/keymaps.lua` adds
**nothing** on top — the delay is purely `ttimeoutlen` (measured with and
without it, real config).

## Why 10 and not 0

`ttimeoutlen=0` is fully instant but *breaks split key-code sequences*: with a
5ms gap between `ESC` and `[D` (Left), nvim delivered the lone `ESC` first and
dropped out of insert mode, then applied `[D` in normal mode (verified). This
is the documented failure mode — `:h 'ttimeoutlen'` says cursor keys "may
fail" on slow systems. `10` keeps a window for sequences arriving within 10ms
(sub-ms on local terminals; the user runs tmux) while removing the
perceptible 50ms wait.

## Relevant code

- `lua/init/options.lua` — `vim.opt.ttimeoutlen = 10` (next to `timeoutlen`).
- Neovim TUI: `src/nvim/tui/input.c` — libtermkey `TERMKEY_FLAG_NOSTART`;
  on `TERMKEY_RES_AGAIN` (incomplete sequence) it starts a
  `ttimeoutlen` timer (`tinput_timer_cb`), then `termkey_getkey_force`.
- `src/nvim/getchar.c` — the "handle `<Esc>` in Insert mode" fast path
  (`inchar(..., 25)`) only applies when `typebuf.tb_maplen == 0`.

## Which keys are affected

Every key whose byte sequence starts with `ESC` — all arrows incl. modified
variants (`ESC[1;5A` …), Home/End, PgUp/PgDn, Insert/Delete, Shift+Tab
(`ESC[Z`), F-keys, Alt+any-key (`ESC`+char), Ctrl+Tab / Ctrl+Shift+Tab via
xterm modifyOtherKeys (`ESC[27;5;9~`), Ctrl+[ (the ESC byte itself), bracketed
paste framing. Plain letters/digits/`C-` combos are single bytes and never
wait.

Verified in this environment (nvim → tmux 3.7 → ghostty): nvim sends the kitty
keyboard-protocol query `ESC[?u` but tmux answers it, so nvim falls back to
xterm modifyOtherKeys (`ESC[>4;2m`) — captured nvim's raw startup bytes via
`tmux pipe-pane`. Without tmux (ghostty directly) the kitty protocol
negotiates and *every* key becomes `ESC[code;mods u`.

## Why 10ms is safe (boundary measured)

Failure requires a split sequence: bytes arriving in separate reads with a gap
> `ttimeoutlen`. Measured by splitting `ESC[D` across reads (insert mode,
checking mode+col): at `ttimeoutlen=10`, gaps ≤10ms keep the arrow intact,
≥11ms fire `ESC` alone. Real gaps are ~0ms — a terminal writes a key's bytes
in one syscall and the pty delivers them in one read, so the timer only ever
starts for a lone `ESC`. Only pathological links (fragmented writes, very slow
remote) exceed 10ms; the failure is a benign mis-read key. Raise `ttimeoutlen`
when working over slow remotes.
