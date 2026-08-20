# Terminal follow in unfocused windows

Findings from fixing: when running pi in a `:terminal` buffer, the window
tailed output while focused, but froze once focus moved to another split.

## Root cause (verified empirically)

Neovim only keeps a terminal window scrolled to the newest output while the
window's cursor sits **exactly** on the last buffer line. From
`adjust_topline_cursor()` in `src/nvim/terminal.c`:

```c
FOR_ALL_TAB_WINDOWS(tp, wp) {
  if (wp->w_buffer == buf) {
    if (wp == curwin && is_focused(term)) {
      // Move window cursor to terminal cursor's position and "follow" output.
      terminal_check_cursor();
      continue;
    }
    bool following = ml_end == wp->w_cursor.lnum + added;  // cursor at end?
    if (following) {
      // "Follow" the terminal output
      wp->w_cursor.lnum = ml_end;
      set_topline(wp, MAX(wp->w_cursor.lnum - wp->w_view_height + 1, 1));
    } ...
```

- Focused + in terminal-mode: the cursor is pinned to the terminal's own
  cursor position (`terminal_check_cursor`), so the viewport follows output.
- Unfocused: follow engages **only** when `cursor.lnum == line_count` exactly.

TUIs like pi park their hardware cursor at the input box, a few lines above
the end of the buffer (observed: cursor at line 38 of 41, viewport 28 rows,
and as low as line 8 mid-render). So once the user leaves the window, the
`following` test is false and the viewport never advances, even though the
buffer keeps growing (pi appends lines and scrolls its screen, so
`buf_lines` grows: observed 41 → 55 while unfocused, viewport stuck at
topline 1).

Verified with `top` and an echo loop: with the cursor set exactly to the end
before leaving, unfocused windows *do* keep tailing (the built-in works); the
freeze only happens because TUI cursors aren't at the end.

## Events available for terminal output

- `nvim_buf_attach(..., { on_lines = ... })` fires on terminal output even for
  non-current buffers: `refresh_screen()` calls
  `changed_lines(..., do_buf_event = true)` → `buf_updates_send_changes()`.
- `BufModifiedSet` does **not** fire (terminal buffers are already `modified`;
  the event is only raised from `edit.c`/`normal.c`).
- `WinScrolled` fires too late (only after the window scrolled).

## Fix

`after/plugin/terminal.lua`:

- On `WinLeave` from a terminal window, remember whether it was tailing:
  `lib.term.was_following(cursor_line, line_count, mode)`.
  - `mode == 't'` (left from terminal-mode): always following — the cursor is
    pinned and cannot be scrolled. (Verified `mode()` is still `'t'` at
    `WinLeave` time; the mode transition happens after window switching.)
  - otherwise: following iff `cursor_line >= line_count - 5` (tolerance for
    TUI-parked cursors, e.g. pi's observed 3-line offset).
- On `TermOpen`, `nvim_buf_attach` the terminal buffer. On every line change,
  for each **unfocused** window showing that buffer with the following flag,
  `nvim_win_set_cursor(win, { line_count, 0 })` — which scrolls the viewport
  and re-engages the built-in follow for subsequent refreshes.

`nvim_win_set_cursor` on an unfocused window does scroll it (verified:
topline jumped to `line_count - height + 1`).

Reading-history case is preserved: scroll up in the terminal (normal mode) and
leave → `was_following` is false → no yank (verified: viewport stayed at the
top while pi kept writing).

## Performance (measured with the real config, tmux UI)

- Event-driven: zero cost when the terminal is idle (`on_lines` only fires on
  output; `WinLeave` is once per window leave). No polling, no timers.
- `on_lines` fires per `changed_lines` call. Note the terminal refresh path
  emits `changed_lines` *per scrollback line* (`refresh_scrollback` calls
  `appended_lines_buf`/`deleted_lines_buf` per row), so under heavy output the
  callback rate can be high — that cost exists in Neovim itself, with or
  without any `nvim_buf_attach` consumer.
- To keep the fix's own cost negligible the handler is coalesced with
  `vim.schedule` (one scan per event-loop batch instead of per callback) and
  early-exits once the window cursor is at the end (the built-in follow then
  keeps it there).
- Measured nvim CPU (4-CPU sample avg during 6s of streaming):
  - ~50 lines/s (pi-like): 5.2% with fix vs 5.0% without (+0.2%).
  - pathological flood: 54.9% vs 54.8% (+0.1%); the 55% baseline is the
    terminal refresh itself, not the fix.
