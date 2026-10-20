# The toggle terminal is tab-exclusive

Findings from making the toggle terminal (`<C-/>`) tab-exclusive: every tab
page owns its own terminal, and the toggle key only ever acts on the terminal
of the current tab.

## The state

One global buffer number (`state.toggle_term_bufnr`) cannot describe that: two
tabs cannot own the same terminal. The state is now a map, keyed by tabpage
id:

```lua
state.toggle_term_bufs = {}  -- tabpage id -> buffer
```

Tabpage ids (not tab numbers) are the key: they are stable for the life of the
session, while a tab *number* shifts whenever a tab before it is closed.

`lib.term` grew the accessors around it:

| function | what it answers |
| --- | --- |
| `toggle_term_bufnr(tabid?)` | the terminal of a tab, nil when it has none |
| `set_toggle_term(tabid, bufnr?)` | remember (or forget) a tab's terminal |
| `forget_toggle_term(bufnr)` | forget the terminal of every tab that had it |
| `toggle_term_window(tabid?)` | the window of a tab showing its terminal |
| `toggle_term_docked(tabid?)` | is that window still in the slot the toggle gave it? |
| `is_toggle_term(buffer?)` | is this buffer *some* tab's toggle terminal? |

`is_toggle_term` answers for any tab on purpose: the winbar labels a terminal
`toggle term` (after/plugin/winbar.lua) and the terminal may be showing in
another tab than the one that owns it.

## Finding a tab's window

`vim.fn.bufwinid()` only looks at the **current** tab, and `vim.fn.winlayout()`
only describes the current tab too. Both are needed per tab, so:

- the window of a tab showing a buffer comes from
  `vim.api.nvim_tabpage_list_wins(tabid)` (a window id, not a window number);
- the layout of a tab comes from `vim.fn.winlayout(vim.api.nvim_tabpage_get_number(tabid))`,
  which takes a tab *number* and happily describes a tab that is not current.

`winlayout()` returns window **handles** in nvim 0.12 (`fr_win->handle` in
`src/nvim/eval/window.c`), not window numbers — the same ids
`nvim_tabpage_list_wins()` hands out, so the two can be compared directly.

## When a tab forgets its terminal

A tab's terminal belongs to that tab's bottom slot. It is forgotten when its
window leaves the tab:

- **moved to another tab** (`<C-w>T`): the terminal is displayed elsewhere, so
  the old tab opens a fresh one next time;
- **moved out of the bottom slot** (`<C-w>J`, a vertical split inside the
  terminal): the window is no longer the bottom-most full-width leaf;
- **the tab was closed**: its terminal went with it.

A terminal that is merely **hidden** (the toggle key closed its window) is
still the tab's terminal: the next toggle reopens the very same buffer, with
its scrollback and its running process.

## Catching the move to another tab

`WinResized` only fires for the **current** tab page
(`may_trigger_win_scrolled_resized()` in `src/nvim/window.c` compares the
windows of `curtab`), so it cannot see a window that left for another tab.

`TabNew` fires in the middle of the move, not after it. `<C-w>T` creates the
new tab first — with the terminal still in the old tab — and closes the old
window only afterwards (`src/nvim/window.c`, `nv_window` case `'T'`). At
`TabNew` time the two cases are indistinguishable: both `<C-w>T` and
`:tabnew` from a terminal window have the terminal as the current buffer,
because `win_alloc_firstwin()` gives the new window the current buffer
(`curwin->w_buffer = curbuf`) and `:tabnew` only loads the empty buffer
afterwards (`do_exedit()` in `src/nvim/ex_docmd.c`).

So the check is deferred (`vim.schedule`) and runs when the command is done:
by then the old tab of a `<C-w>T` no longer shows the terminal, while the old
tab of a `:tabnew` still does.

## The check reads every tab

The docked check runs for every tab that owns a terminal, not just the current
one — a resize in another tab must not detach a terminal elsewhere. That is
why the layout has to be read per tab: `winlayout()` without an argument
describes the current tab, and comparing that layout against another tab's
window would report every other tab as "not docked".

## A dead terminal is forgotten

`TermClose` fires when the terminal's process exits. The tab forgets that
terminal, so the next toggle opens a fresh shell instead of the corpse of the
old one.
