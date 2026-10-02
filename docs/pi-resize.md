# Keeping a pi terminal's place across a resize

Findings from fixing: with pi running in a `:terminal` buffer, resizing the
window — a split, a `<C-w>` drag, or the whole nvim UI as a tmux pane changes —
threw the view to the top of the transcript instead of leaving it where it was.

## Cause: pi wipes the scrollback, nvim's buffer _is_ the scrollback

pi's main screen renders into the terminal's normal screen and scrollback
rather than the alternate screen. In `packages/tui/src/tui-main-screen.ts`, a
width change (and, off Termux, a height change) takes the `fullRender(true)`
path, which emits

```
\x1b[2J\x1b[H\x1b[3J   // clear screen, cursor home, clear scrollback
```

and then reprints the whole transcript at the new width.

`\x1b[3J` is the problem. In `src/nvim/terminal.c`:

```c
static int term_sb_clear(void *data)
{
  Terminal *term = data;
  if (term->in_altscreen || !term->sb_size || !term->sb_current) {
    return 1;
  }
  for (size_t i = 0; i < term->sb_current; i++) {
    xfree(term->sb_buffer[i]);
  }
  term->sb_deleted += term->sb_current;
  term->sb_current = 0;
  ...
```

The terminal buffer collapses to the on-screen rows, and
`adjust_topline_cursor()` then clamps every window showing it into what is
left:

```c
bool following = ml_end == wp->w_cursor.lnum + added;  // cursor at end?
if (following) { ... } else {
  // Ensure valid cursor for each window displaying this terminal.
  wp->w_cursor.lnum = MIN(wp->w_cursor.lnum, ml_end);
}
```

The reprint then regrows the buffer _below_ a cursor that is now near the top.
Measured with `nvim_open_term` and 200 lines of output, cursor parked on 50:

| sequence               | line count | cursor |
| ---------------------- | ---------- | ------ |
| (after output)         | 201        | 50     |
| `\x1b[H\x1b[2J`        | 201        | 50     |
| `\x1b[2J\x1b[H\x1b[3J` | 22         | 1      |

A real terminal emulator hides this: its viewport is pinned to the bottom, so a
scrollback wipe is invisible. Neovim's scrollback is a buffer with a cursor in
it, and the cursor is what gets lost. tmux copy-mode has the same trouble.

The focused window in **terminal-mode** escapes it — `adjust_topline_cursor`
hands that one to `terminal_check_cursor()`, which pins it to pi's own cursor.
Normal mode, and every unfocused window, does not.

This is pi's behaviour, not a Neovim misconfiguration; the real fix belongs
upstream (clear the viewport, leave the scrollback alone). What follows is the
mitigation on this side.

## Mitigation: hold the distance from the end

In `after/plugin/pi.lua`, on `VimResized` and `WinResized`:

1. **Snapshot**, synchronously in the autocmd, every window showing a pi
   terminal: how many lines sat between its cursor and the end of the buffer.
   Running before nvim returns to the event loop is what makes the reading
   pre-redraw — pi has not even been signalled yet, since nvim pushes the new
   size to the pty from the redraw path.
2. **Hold**: on every batch of terminal output, put each window back at
   `line_count - from_end`.
3. **Release** once pi has redrawn and the reprint has stopped growing the
   buffer, or at a deadline.

Exact for the common case of sitting at pi's input box. Approximate when the
new width rewraps the transcript into a different number of lines — there is no
better answer available, because the content the position referred to no longer
exists in the same shape.

### Holding, not restoring: where the flicker came from

Repairing the position _after_ the fact is visibly wrong even when the final
position is right: the clamped viewport gets drawn at the top of the buffer for
as long as the repair takes, and then snaps back. Frames rendered for the pi
window, captured with `nvim_set_decoration_provider`'s `on_win` (which reports
the `toprow` each window was actually drawn with):

| implementation             | frames drawn at the top   |
| -------------------------- | ------------------------- |
| no mitigation              | 7/7                       |
| restore once, when quiet   | 7/8, correct from t+201ms |
| hold on every output batch | 0/7                       |

So the anchor is re-applied on every `on_lines`, which puts it back in the same
event-loop iteration that disturbed it — before anything is drawn.

### Why the re-apply must be scheduled, not inline

`on_lines` fires from inside `refresh_terminal` (`src/nvim/terminal.c`), and the
clamp runs _after_ all of it:

```c
bool resized = refresh_size(term, buf);
refresh_scrollback(term, buf);   // deleted_lines_buf/appended_lines_buf -> on_lines
refresh_screen(term, buf);       // changed_lines -> on_lines

int ml_added = buf->b_ml.ml_line_count - ml_before;
adjust_topline_cursor(term, buf, ml_added);   // the clamp
```

A cursor written inline from `on_lines` would simply be clamped in its turn.
`vim.schedule` lands the write after `refresh_terminal` returns and still before
`normal_check` reaches `update_screen`, which is the window the fix needs.
(`nvim_win_set_cursor` is permitted in both positions — no textlock — so the
inline version fails silently rather than erroring, which is worth knowing.)

Scheduling also coalesces. `on_lines` fires once per scrollback line — the
refresh path calls `appended_lines_buf`/`deleted_lines_buf` per row — and one
re-apply per event-loop batch is all that is needed. This is the same trick the
follow handler in the same file uses, for the same reason.

### The two constants

Both only govern _release_. Neither gates when the viewport becomes correct,
which is what made them worth loosening: under the old restore-once design
`SETTLE_MS` was the flicker duration.

- `SETTLE_MS = 100` — poll interval for noticing the reprint has stopped. Too
  low wastes wakeups during a resize; too high only delays the handover back to
  normal scrolling and the follow handler. Nothing visible either way.
- `SETTLE_DEADLINE_MS = 2000` — the longest a hold may last. It exists because
  two cases never settle: a resize that leaves pi's character grid unchanged
  (so it never redraws at all) and a reply streaming in (so the buffer never
  goes quiet). A hold that outlived its redraw would fight the user's own
  scrolling, so holding forever is not an option; 2s is far longer than pi's
  observed reaction, and nothing is at stake in the cases that reach it.

Settled means pi has written _something_ since the resize and the line count
then held steady across two polls. The "something" matters on its own: a resize
that does not rewrap reprints to exactly the same line count, so the count alone
cannot distinguish "finished" from "not started".

### Windows left alone

The focused window in terminal-mode: nvim already pins it to pi's own cursor,
so writing anywhere else only fights `terminal_check_cursor`.

A second resize while a hold is in force (dragging a split) keeps the original
anchor rather than re-reading the already-clamped cursors.

## Interaction with terminal follow

Both consumers now share one `nvim_buf_attach`. They do not conflict: a window
the follow handler tracks is one that was tailing, so its anchor is at or
within a few lines of the end, and both want it at the bottom. A window that
was not tailing before the resize is not made to tail by the hold.

See [terminal-follow.md](terminal-follow.md).

## Verification

`tests/integration/test_pi_resize.lua`, driven by a script named `pi` that
reproduces just the SIGWINCH behaviour. It asserts two things:

- both windows end up their recorded distance from the end of the transcript;
- no frame was ever _drawn_ at the top of the buffer, from the `on_win`
  toprows, ignoring frames taken while the wipe had the buffer collapsed to the
  window height (where the top is the only thing nvim can draw).

The frame assertion is the one that pins the current design. Checked against a
rebuilt restore-once implementation, which passes the position assertion and
fails the frame one: `7 of 10 frames were drawn at the top of the buffer`.

Two things force the test's shape:

- `nvim -l` never enters normal mode's main loop, and that is where nvim raises
  `WinResized` (`may_trigger_win_scrolled_resized` in `normal.c`) _and_ redraws,
  which is the only path that pushes a window's new size to the pty
  (`terminal_check_size`, called from `win_update` in `drawscreen.c`). So the
  test re-execs itself under plain `--headless` and hands back the exit code.
- Under that loop the test body has to yield control back, so it runs as a
  coroutine whose `pause(ms)` resumes from `vim.defer_fn`.

Also confirmed against real pi 0.99.1 (`:term pi`, `/help` for a transcript
long enough to have scrollback, cursor parked 5 lines from the end, then
`:vertical resize` to half width, which grew the buffer 65 -> 146 lines):

| implementation             | resulting `from_end` | frames drawn at the top |
| -------------------------- | -------------------- | ----------------------- |
| no mitigation              | 145 (top of buffer)  | 3/3                     |
| restore once, when quiet   | 5                    | 1/4                     |
| hold on every output batch | 5                    | 0/3                     |

Unrelated to this change, `vim.o.columns = 200` in headless nvim 0.12.5 aborts
with "double free or corruption"; the test leaves `columns` alone.
