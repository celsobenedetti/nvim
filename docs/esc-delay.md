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
