# Winbar eager rendering for new buffers

Findings from fixing: the winbar did not render eagerly when entering a new
buffer — reproduced with a fresh `:terminal`. Also settles how winbar redraws
are scheduled in Neovim (relevant to `%!` winbar performance).

## Root cause (verified empirically)

For a fresh `:term` (and `:vsplit | term`, `botright sp | term`, ...) Neovim
fires autocmds in this order:

```
BufAdd → BufEnter → BufWinEnter   (buftype='' , ft='')
TermOpen                            (buftype='terminal', ft set here)
```

- `buftype='terminal'` is set by `terminal_open()` in `src/nvim/terminal.c`
  *before* it applies `TermOpen` autocmds.
- The config's own `ft='terminal'` is set in the `TermOpen` handler in
  `after/plugin/terminal.lua` (`vim.bo.filetype = 'terminal'`).

So at `BufWinEnter` time the buffer has **both** `buftype=''` and `ft=''`.
The old winbar callback matched `SPECIAL_FILETYPES` on `ft` at
`BufWinEnter`, missed `terminal`, and installed the generic
`%!v:lua.get_winbar()` — and `get_winbar()` returned `''` for any
`buftype ~= ''`. The terminal winbar was therefore permanently empty.

Normal file buffers were unaffected: their `FileType` fires before
`BufWinEnter` (detection happens at buffer load), so the filetype-based
branch matched.

## Which events fire (splits vs same-window buffer switches)

Trace of `edit a.lua` / `vsplit` / `edit b.lua` / `split`:

| action | events |
|---|---|
| `:edit <file>` in the current window | `BufWinEnter` only |
| `:vsplit` / `:split` (new window) | `WinEnter` (new window gets focus; no `BufWinEnter` if it shows an already-displayed buffer) |
| `:edit <file>` inside the new split | `BufWinEnter` only |

So **WinEnter does fire on splits**, and `BufWinEnter` covers buffer switches
in the same window. The `{ 'BufWinEnter', 'WinEnter' }` pair is sufficient —
the bug was the render path, not the event set.

## Fix (`after/plugin/winbar.lua`)

1. **Special-filetype resolution moved into `get_winbar()`**, i.e. into the
   `%!` expression that Neovim re-evaluates on every statusline/winbar
   redraw. The bar now always reflects the buffer's *current* state, immune
   to autocmd ordering — a fresh terminal renders `  terminal` as soon as
   `TermOpen` sets the filetype and the command completes (the new window's
   first full draw, `UPD_NOT_VALID`, re-evaluates the bar).
2. **Special-case functions receive the rendered window's buffer**
   (`special(buf)` resolved via `g:statusline_winid`), not the focused
   buffer — correct when an *unfocused* window renders its own bar.
3. **Autocmd now only installs the `%!` expression**, and only when the
   window's current winbar is empty or already ours. This preserves
   plugin-owned bars: oil sets its own winbar
   (`win_options.winbar = '%!v:lua.get_oil_winbar()'`) the moment its buffer
   is shown, and its `buftype` is still `''` at `BufWinEnter` — so the old
   `buftype == 'nofile'` early-return did **not** protect it (the old code
   transiently clobbered it and oil re-applied it; the new guard skips it
   entirely).
4. **The autocmd skips windows that can't hold a winbar.** Setting a winbar
   on a floating window with view height `<= 1` makes nvim raise
   `E36: Not enough room` inside the `BufWinEnter` autocommands, which
   aborts the caller's `nvim_open_win` — the snacks picker input window
   (1-line float in `ivy`/`vscode` layouts) and blink.cmp's completion float
   both died on `<leader>si`. Two guards: `nofile` buffers (pickers, cmp,
   notifier — they render an empty bar anyway, restoring the pre-refactor
   early-return) and floats with `winheight() <= 1` (`winheight()` returns
   `w_view_height`, the exact value nvim checks).

## How winbar redraws are scheduled (the C side)

From `drawscreen.c` (`win_update`), the statusline and winbar share **one
dirty flag** and are drawn together, after the window content:

```c
if (wp->w_redr_status) {
  win_redr_winbar(wp);   // redraw the bar above the window
  win_redr_status(wp);   // redraw the bar below the window
}
```

- `w_redr_status` is a boolean "dirty" marker. ~20 sites in the source just
  set `wp->w_redr_status = true` (cheap) when something invalidates the bars:
  `win_update` with `w_redr_type >= UPD_NOT_VALID` (full window redraws),
  cursor moves, mouse moves, buffer switches, `:cd`, `:redrawstatus`, ex
  commands. The actual (comparatively expensive) drawing happens at most once
  per screen update, even if the flag was set many times in between.
- **Terminal output does NOT set it.** Output redraws mark the window
  `UPD_SOME_VALID` / `UPD_VALID` (`redraw_later` in `src/nvim/terminal.c`),
  which is below the `UPD_NOT_VALID` threshold — so a busy terminal does not
  re-evaluate its winbar per output batch.
- `win_redr_winbar` (statusline.c) no-ops when the window has no winbar row
  (`w_winbar_height == 0`) or no winbar option set, and guards against
  recursion (`static bool entered`) in case a `%!` expression triggers a
  redraw. `win_redr_status` clears the shared flag at its top, so the pair
  runs once per invalidation cycle.

## `%!` winbars resolve the right window

For `%!` formats Neovim sets `g:statusline_winid` to the window being drawn
before evaluating and unsets it after (`set_var`/`do_unlet` around the eval
in `statusline.c`). This is why a single global `%!v:lua.get_winbar()`
renders each window's own buffer — including unfocused windows.

## Performance

The winbar `%!` is evaluated exactly as often as the statusline `%!`: the
same `w_redr_status` flag gates both, and the config already evaluates
`%!v:lua.MyStatusLine()` (a much heavier function) under those conditions.
Per-eval cost delta vs the old static strings: a `SPECIAL_FILETYPES` table
lookup for file windows; a few integer/buftype comparisons + concat for
terminal windows; one `pcall(vim.fn.FugitiveResult, buf)` per status-redraw
for git/fugitive windows (those only redraw on cursor moves / refreshes).
Terminal output storms do not multiply evaluations (`UPD_SOME_VALID` skips
the winbar), so the cost is bounded by real UI events — tens of evals per
second across all windows at most, noise against grid rendering itself.
