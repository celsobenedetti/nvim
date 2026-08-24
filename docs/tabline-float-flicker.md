# Tabline flicker when blink.cmp's completion menu opens

Fixing: individual tabs briefly rendered `[No Name]` (or lost their terminal
label) whenever the blink.cmp menu popped up during insert-mode typing.

## Root cause

`after/plugin/tabs.lua` redraws the tabline on
`{ TabNew, TabClosed, WinEnter, BufEnter, BufWinEnter, TermOpen }`. Opening a
completion float fires those events for the float's scratch buffer — and
**while `nvim_open_win` runs, Neovim makes the new float the tab's current
window even with `enter=false`** (restored right after). Any `%!` tabline
evaluation landing inside that window-of-time saw:

```
t=7101ms | tab1: curwin=<menu-float> buf=8 name=[]   ← mid-open
t=7103ms | tab1: curwin=1000 buf=1 name=[fixture.lua] ← restored
```

so `lib.tab.fallback_name()` read the float's unnamed scratch buffer and the
tab flipped `[No Name]` ⇄ real label across two redraws — visible flicker.
The same flaw made `single_buffer_bufnr()` count float buffers, hiding the
special (terminal) label of single-buffer tabs while any float was up.

Verified at the byte level with `tmux pipe-pane`: pre-fix, four row-1 writes
per menu pop, two containing `[No Name]`; post-fix, zero row-1 writes
(identical tabline content emits no bytes).

## Fix (`lua/lib/tab.lua`)

Float-aware resolution instead of raw `nvim_tabpage_get_win()`:

- `shown_window(tabid)` returns the tab's current window unless it is
  floating (`nvim_win_get_config(win).relative ~= ''`), falling back to the
  tab's first normal window.
- `single_buffer_bufnr(tabid)` counts only normal windows' buffers.

## Testing traps hit along the way

- **Neovim's rtp-based Lua loader beats `package.path`.** Under `-u NONE`,
  `~/.config/nvim` stays on 'runtimepath', so `require('lib.tab')` in tests
  silently loaded the *live* module even with the repo prepended to
  `package.path` (AGENTS.md warns about this). Fix: prepend the repo root to
  `'runtimepath'` itself (`vim.opt.runtimepath:prepend(repo_root)`); for full
  e2e sessions, `XDG_CONFIG_HOME` pointed at a dir whose `nvim` symlink is
  the worktree — `--cmd 'set rtp^=...'` is NOT enough once lazy.nvim rebuilds
  rtp.
- **Simulating the transient**: `nvim_set_current_win(float)` after the fact
  does not always reproduce it (`nvim_tabpage_get_win()` may keep returning
  the main window); the integration test asserts through `lib.tab.get_name()`
  which is sensitive to either path.
