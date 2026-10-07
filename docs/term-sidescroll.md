# Terminal TUIs shift left when you leave the window

Findings from fixing: with a vertical split and a `:Hunk` terminal on the
right, jumping to the left window (`<C-h>`) drew the hunk TUI a few columns
too far left, blanking the last columns of the window. Resizing the window
fixed it; the next jump brought it back.

Not specific to hunk or to tmux — any full-screen TUI in a `:terminal` window
does it.

## Cause

Two options combine:

```lua
vim.opt.wrap = false        -- lua/init/options.lua
vim.opt.sidescrolloff = 8   -- lua/init/options.lua
```

In a `nowrap` window nvim scrolls horizontally (`w_leftcol`) to keep
'sidescrolloff' columns of context around the cursor. Terminal-mode normally
hides this: `terminal_enter()` saves `w_p_siso` and zeroes it, because the
cursor is pinned to the terminal's own cursor and cannot be moved
(`src/nvim/terminal.c`, "Disable these options in terminal-mode"). `scrolloff`
gets the same treatment, which is what the existing `vim.opt_local.scrolloff =
0` in the `TermOpen` autocmd mirrors.

`terminal_leave()` restores the saved value. So the moment you leave
terminal-mode the window is `nowrap` with `sidescrolloff=8` again, the cursor
sits near the right edge of the last line, and nvim scrolls right to give it
context.

Instrumenting the terminal window across a `<C-h>` jump shows it exactly — the
`WinScrolled` between `TermLeave` and the next event is the glitch:

```
TermLeave      width=79 textarea=79 leftcol=0 siso=0 wrap=false mode=t
TermLeave      width=79 textarea=79 leftcol=0 siso=8 wrap=false mode=nt
WinScrolled    width=79 textarea=79 leftcol=7 siso=8 wrap=false mode=nt
```

`leftcol=7` with a grid exactly as wide as the text area means the first 7
columns are scrolled off and the last 7 are blank. `TermEnter` zeroes `siso`
again but never resets `leftcol`, so the shift persists until something
re-validates the cursor columns — which is why resizing the window "fixes" it.

## The fix

Pin 'sidescrolloff' off for terminal windows, next to the existing 'scrolloff'
line in the `TermOpen` autocmd (`after/plugin/terminal.lua`):

```lua
vim.opt_local.sidescrolloff = 0
```

The terminal grid is sized to the window's text area (`terminal_check_size()`
uses `w_view_width - win_col_off(wp)`), so there is never anything off-screen
to scroll to — horizontal scrolling in a terminal window is only ever the bug.

`terminal_enter`/`terminal_leave` save and restore the window-local value, so
with it at 0 the restore is a no-op.

## Reproducing

`sidescrolloff` is window-local with a global default, and `TermOpen` only
sets the window the terminal opens in — the same caveat the neighbouring
`number` and `scrolloff` lines already have.

Drive a real UI; headless nvim never redraws, so the statuscolumn and
`w_leftcol` are never computed:

```sh
tmux new-session -d -s probe -x 160 -y 45 'nvim -c "luafile /tmp/watch.lua"'
tmux send-keys -t probe ':leftabove vsplit init.lua' Enter
tmux send-keys -t probe C-w l
tmux send-keys -t probe ':terminal hunk diff HEAD~1' Enter
tmux send-keys -t probe C-h          # the jump
tmux capture-pane -p -t probe
```

Log the geometry from an autocmd rather than over RPC — `--remote-expr`
forces a redraw that hides the glitch. `leftcol` is not in `getwininfo()`:

```lua
vim.api.nvim_win_call(win, function() return vim.fn.winsaveview().leftcol end)
```
