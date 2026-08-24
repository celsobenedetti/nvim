# Diff tree sidebar (`:DiffTree`)

An InspectTree-like outline of a `filetype=git` diff buffer, in a left-side
split. It shows only the `diff` grammar's two navigable sections — per-file
`block`s and their `hunk`s — and reuses `:InspectTree`'s interaction model:
hovering a row scrolls the section to the top of the diff buffer and unfolds
it, `<CR>` jumps there, and the diff buffer's own cursor keeps the tree in
sync.

## Surface

- `:Diff [rev] [rev2]` — the default index for a new diff tab: the patch on
  the right, this tree on the left and focused (`lib.Diff.open`). `:DiffQf` is
  the older quickfix-of-files flavour (`lib.Diff.open_qf`); both share
  `patch_tab()`, which opens the fugitive tab and waits for its job. See
  `after/plugin/Diff.lua`.
- `:DiffTree` (any buffer that parses as `diff`) — see `after/plugin/Diff.lua`.
- `glt` in `filetype=git` patch buffers — see `after/ftplugin/git.lua`.
- The last two call `lib.Diff.open_tree()`, which toggles: a second call closes
  the tree.

The git→diff treesitter alias (`after/plugin/autocmds.lua`, see
`docs/ts-git-diff-alias.md`) makes fugitive patch buffers parse with the
`diff` grammar, so the tree works on `:Diff`, `:Git diff/show/log -p`.

## Rows

`lib.Diff.tree_rows(bufnr)` walks the parse tree and emits one row per
section, in document order:

- **block** (top level): `<icon> <path> <summary>` — path from the `+++ b/x`
  line (falling back to the `diff --git` command's last path token, and to
  `/dev/null`-aware handling for deletions); summary is the `+N -M` delta,
  padded so summaries align.
- **hunk** (indented two spaces under its block): the full `@@ -a,b +c,d @@`
  line, including git's trailing function/class heading.

Each row carries `lnum` (1-based jump target) and `range` (0-based node span,
used for containment and for the range hover unfolds). Hunk rows also carry
their block's `path`, so file-scoped actions (`ga`) work from either row kind.

## Interaction (mirrors `:InspectTree`)

- **Hover** — `CursorMoved` in the tree (`M.tree_focus`) does three things to
  the diff window, and never moves focus out of the tree; only `<CR>` moves
  you:
  1. **unfold the section** — `zO` over the row's whole `range`, sent as the
     range form `:{a},{b}foldopen!` (every fold in the range, nested ones
     included), so a file row reveals all of its hunks. A plain `zO` would only
     open the folds *containing the cursor line*, leaving the hunks below it
     closed. A node that ends at a line break reports the next row with column
     0, so the last line is `erow` when `ecol == 0` — otherwise a block would
     unfold its neighbour's first fold too. Nothing foldable in the range is an
     `E490`, silently ignored here (unlike the explicit `zo` mapping, which
     reports it).
  2. **park it on top** — `zt`, on every hover and not only when the section is
     off-screen. It **respects the diff window's `'scrolloff'`**: the section
     lands that many lines below the top edge, keeping the usual margin of
     context. That needs the diff window's cursor to move there too (see the
     gotcha below).
  3. **highlight, blocks only** — a block row re-emits lib.diff_filepath's
     overlay bar on its hover palette (`DiffFileBarHover*`); the header line's
     visible pixels belong to that extmark, whose `virt_text` chunks no second
     extmark can restyle. Hunk rows paint nothing in the diff buffer — the
     scroll is the feedback.
  4. **refresh the sticky context** — nvim-treesitter-context for the *diff*
     window, so hovering a hunk keeps its `diff --git` header (filepath bar
     included, see `docs/diff-filepath-bar.md`) pinned above it even though the
     cursor is in the tree. The plugin only ever updates the **current** window
     (`nvim_get_current_win()` in its `CursorMoved`/`WinScrolled` handler, and
     `WinScrolled` is not one of its multiwindow events), so `refresh_context`
     drives its two winid-parameterized internals for the diff window itself:
     `treesitter-context.context.get(win)` → `render.open(win, …)`, or
     `render.close(win)` when there is no context. It no-ops when the plugin is
     absent (`-u NONE` in the tests) or switched off (`:TSContextToggle`), and
     runs *after* the `zt` — the context is computed from the window's topline.
     The diff grammar's context query is `[(block) (hunk)] @context`, so a hunk
     hover pins the file header and a block hover has nothing above it to pin
     (the float is closed).
- **`<CR>`** — jumps the diff window's cursor to the row's `lnum`, reusing a
  window that already shows the diff buffer (never splitting a new one; the
  same workaround as `lib.Diff.install_qf_jump` for `buftype=nowrite`).
- **`q`** — closes the tree.
- **`ga`** — stages the row's file via `lib.git.add` (same flow as
  `ga` in a normal buffer or in the patch buffer — `Git add -p` for unstaged
  changes, plain `git add` when untracked). Focus moves to the diff window
  first, so fugitive's interactive split doesn't open inside the 30-column
  sidebar. From a hunk row it stages the whole file (rows carry their block's
  path).
- **`z` fold commands** — fold the **diff buffer**, mirrored onto the tree.
  `lib.Diff.tree_fold(tree_buf, key)` drives all of them from one spec table
  (`TREE_FOLD_ACTIONS`):
  - *line-scoped* `za` `zA` `zc` `zC` `zo` `zO` — act on the row's section: a
    file row folds its whole `diff --git` block, a hunk row its `@@` section.
    `toggle` (`za`/`zA`) reads the current state, the capitals pass `!` for the
    recursive form. Sent as the range form (`:{lnum}foldclose`), which acts on
    a line **without moving the diff window's cursor** — unlike `normal! zc`.
    Note the native scoping: a command only touches folds containing that line,
    so `zC` from a *hunk* row is what closes the enclosing block.
    File rows mirror the new state onto the tree's own fold, so a collapsed
    file hides its hunk rows here too; hunk rows have no tree fold to mirror.
  - *window-wide* `zR` `zM` `zr` `zm` — only move the window's `'foldlevel'`,
    so they are cursor-independent and get forwarded verbatim (with a count:
    `3zm`), then re-run in the tree window: `zM` collapses the tree to one row
    per file, `zR` expands both again.
  - not forwarded (act on the tree only): `zv`, `zx`/`zX`, `zn`/`zN`/`zi`, and
    the `zj`/`zk` motions. Folding in the diff buffer itself is not mirrored
    back onto the tree.
  - a row with no fold at all (binary/rename block, or folds off) notifies
    once; a repeated `zo`/`zc` in the same direction is a silent no-op (that is
    an `E490` from `:foldopen`/`:foldclose`).
- **Bidirectional** — `CursorMoved` in the diff buffer moves the tree cursor
  to the deepest row (hunk over block) containing the source cursor.
- **Fold (the tree's own)** — `foldmethod=expr` +
  `lib.Diff.tree_foldexpr()`: a block is a fold header (`>1`) when it has
  hunks, hunks sit inside it (`1`). `zc`/`zo` on a block folds its hunks;
  blocks without hunks (binary/rename) don't fold.

`'scrolloff'` doubles as the room the context float needs: at the default 4,
`zt` leaves four lines above the section and the float (`max_lines = 3`) paints
over those instead of over the section itself.

## Lifecycle

`open_tree` records the tree window and an augroup on the source buffer
(`vim.b.diff_tree_win` / `diff_tree_group`); it changes no window options
there. The tree closes (and the group is deleted) on: `q`, a second
`:DiffTree`, or `BufHidden`/`BufUnload` of the source buffer. Leaving the tree
drops the hovered block's bar back to its normal palette.

## Testing

`tests/integration/test_diff_tree.lua` (`make test-integration`) covers
`tree_rows` (paths, summaries, `@@` text, ranges), `tree_row_containing`, the
rendered buffer lines, the fold options **and the resulting fold levels**, the
hovered block's bar (and that hunk rows paint nothing), hover's `zt` (topline
with a non-zero `'scrolloff'`, the source cursor) and its unfold, the `<CR>`
jump, every forwarded fold command (`za`/`zA`/`zc`/`zC`/`zo`/`zO` on both row
kinds, `zR`/`zM`/`zr` incl. a count, plus the tree mirror and the no-op
repeats), the `ga` hand-off to `lib.git`, and the toggle-close.
`lib.git.add` itself is covered against a throwaway repo in
`tests/integration/test_diff_ga.lua`.

## Gotchas

- **A window's cursor pins its view.** nvim keeps the cursor on screen, so a
  `winrestview({ topline = … })` that would scroll it out of view is undone —
  the pre-`zt` "reveal if off-screen" scroll therefore did nothing for any
  section further away than a screen. Hover moves the diff window's cursor to
  the section and then `zt`s. Moving a **non-current** window's cursor fires no
  `CursorMoved`, so the source→tree sync autocmd cannot loop back on this.
- **`CursorMoved` never fires under `--headless`** (no UI). The hover and
  bidirectional autocmds can't be driven by feeding cursor moves in tests;
  `tree_focus` / `tree_row_containing` are called directly instead.
- **`index` commit hashes must be 4–64 hex chars** for the `diff` grammar to
  keep parsing a block; short fake hashes (`index 111..222`) turn the section
  into an ERROR node and drop its hunks. Tests use `1111111..2222222`.
- **Buffer vars before `foldmethod`**: assigning `'foldmethod'` evaluates the
  foldexpr immediately. `open_tree` used to store `vim.b.diff_tree_rows` after
  setting the option, so that first evaluation saw no rows, cached level 0 for
  every line, and — nothing ever edits the tree buffer to invalidate the cache
  — no row folded, in the tree or (once the `z` forwarding existed) anywhere. The rows are now
  stored first; the test asserts `foldlevel()`, not just the option values.
- **`multiwindow = true` is required** (`lua/plugins/treesitter.lua`). With it
  off, nvim-treesitter-context binds its close handler to `WinLeave`/`BufLeave`
  — entering the tree would close the diff window's context — and every update
  it runs for the tree window calls `Render.close_contexts({ tree_win })`,
  garbage-collecting the context we just opened for the diff window. The flag
  is global, so contexts now render in every visible window, not only the
  current one.
- **Folds in the diff window**: the forwarded `z` commands need real folds
  there, so
  `after/ftplugin/git.lua` sets `foldmethod=expr` +
  `v:lua.vim.treesitter.foldexpr()` per patch window (the diff grammar's
  `folds.scm` captures `block`, `hunks`, `hunk`). The global default is
  `indent`, and the treesitter plugin only stamps expr folding on whichever
  window is current when it configures itself.
- **Deletions** emit `+++ /dev/null`; `block_path` treats that as "no new
  path" and falls back to the `diff --git` command line (the pre-existing
  quickfix builder did not, and would label a deleted file `dev/null`).
