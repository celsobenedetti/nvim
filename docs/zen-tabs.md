# Zen mode is tab-exclusive

Findings from making `Snacks.zen` (`<leader>uz`) tab-exclusive: every tab page
owns its own zen window, and navigating to another tab leaves the first tab's
zen open.

## Floats are already per tab

A window created with `nvim_open_win` and `relative ~= ''` belongs to the
**tabpage that was current** when it was created (`nvim_win_get_tabpage`).
Switching tabs does not close it: the window stays valid and is drawn again
when its tab becomes current, and that tab's current window is the float
(Neovim remembers the current window per tab). So a zen window per tab is
possible; `Snacks.zen` is what blocks it.

## What blocks it

`lua/snacks/zen.lua` in snacks:

| where | blocker |
| --- | --- |
| `M.win` module singleton | `M.zen()` starts with "close if already open", so opening zen in tab 2 closes tab 1's |
| `win:on("WinEnter", …)` | closes zen when a non-float window is entered, and **a tab switch enters a window** — verified: `:tabnext` fires `WinEnter` before `TabEnter` |
| the win's own autocmd group | that `WinEnter` autocmd lands in `snacks_win_<id>` as a global-pattern autocmd, not one scoped with `win = true` |

**Registration order matters**: `M.zen()` calls `opts.on_open(win)` *before*
`win:on("WinEnter", …)`. Deleting the autocmd from inside `on_open` deletes
nothing; the wrapper has to patch after `Snacks.zen()` returns. Worse, the
zen's own handler schedules a close with `vim.schedule`, so a handler that was
already armed closes the window later (at the next event loop turn), which
looks like an unrelated command closing zen.

## The state

One global flag cannot describe two tabs, and `state.zen_mode` was never read
anyway (only written). Gone. `lua/lib/zen.lua` keeps the windows in a map keyed
by **tabpage id** (same reasoning as `state.toggle_term_bufs`, see
`docs/toggle-term-tabs.md`: ids are stable, tab *numbers* are not):

```lua
local wins = {}  -- tabpage id -> snacks.win
```

| function | what it answers |
| --- | --- |
| `zen.get(tabid?)` | the zen window of a tab, nil when it has none |
| `zen.any()` | is any zen open, in any tab |
| `zen.toggle(opts?)` | toggle zen for the current tab, leaving other tabs alone |

`toggle` does three things around the `Snacks.zen` call:

1. `Snacks.zen.win = nil` first, so the singleton does not close another tab's zen;
2. wraps `on_close` to forget the tab's entry — it also runs when the **tab
   itself** is closed (verified: `:tabclose` fires `WinClosed` → zen's
   `on_close`), so no extra `TabClosed` cleanup is needed;
3. after the call, deletes zen's `WinEnter` autocmd from `win.augroup` and
   installs a tab-aware one: close zen only when the entered window is
   non-float **and in the same tab**.

`previously` `Snacks.zen.win` was the only way to ask "is zen open"
(`lua/plugins/secondary/tmux.lua`'s `<C-h>`). It now points at whichever zen
opened last, possibly in another tab; use `zen.get()`.

## The `Folded` highlight is global

`zen.lua` greys `Folded` on open and links it back to `Normal` on close. With
several zens open, the close of one must not restore it while another is still
up, so the restore is guarded by `lib.zen.any()` — which only works because
the closing tab's entry is removed before its `on_close` hook runs.

## `show.tabline` covers the tabline

`get_main()` in snacks only reserves a row for the tabline when
`show.tabline = true`; with `false` the zen float and its backdrop sit on
`row = 0` and cover the tabline (measured: `row 0, height 39` at 40 lines vs
`row 1, height 38`). A tab-exclusive zen is useless if you cannot see the tabs
to switch to, so the config now says `tabline = true`.

## Testing

`tests/integration/test_zen_tabs.lua` runs under `make test-integration`
(`nvim --headless -u NONE -l`). It prepends both the repo and
`~/.local/share/nvim/lazy/snacks.nvim` to `'runtimepath'` and calls
`require('snacks').setup({})` — zen is real, not mocked. It asserts two tabs
with zen at once, that a tab switch keeps zen, that `vsplit` in the same tab
closes it, and that `:tabclose` forgets the tab's entry.

`lib.zen.toggle` must not mutate the caller's `opts` table (it replaces
`on_close`); it shallow-copies it, otherwise reusing one hooks table across
toggles nests the wrappers.
