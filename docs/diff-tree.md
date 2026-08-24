# Diff tree sidebar (`:DiffTree`)

An InspectTree-like outline of a `filetype=git` diff buffer, in a left-side
split. It shows only the `diff` grammar's two navigable sections — per-file
`block`s and their `hunk`s — and reuses `:InspectTree`'s interaction model:
hovering a row scrolls the section to the top of the diff buffer and
highlights it, `<CR>` jumps there, and the diff buffer's own cursor keeps the
tree in sync.

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
used for containment and hover highlight). Hunk rows also carry their block's
`path`, so file-scoped actions (`ga`) work from either row kind.

## Interaction (mirrors `:InspectTree`)

- **Hover** — `CursorMoved` in the tree clears the previous highlight and
  paints an extmark (`hl_group = Visual`) in the diff buffer: blocks
  highlight just their `diff --git` header line, hunks highlight their whole
  range. The section is then parked on the diff window's **first line** (`zt`),
  every hover, not only when it is off-screen. That needs the diff window's
  cursor to move there too (see the gotcha below) and its `'scrolloff'` zeroed
  — `open_tree` saves and zeroes it, `close_tree`/the toggle restore it. Focus
  stays in the tree, so hover still isn't a jump; only `<CR>` moves you.
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

## Lifecycle

`open_tree` records the tree window, an augroup, and the diff window's saved
`'scrolloff'` on the source buffer (`vim.b.diff_tree_win` /
`diff_tree_group` / `diff_tree_src_scrolloff`). The tree closes (and the group
is deleted, the `'scrolloff'` restored) on: `q`, a second `:DiffTree`, or
`BufHidden`/`BufUnload` of the source buffer. Leaving the tree clears the hover
highlight.

## Testing

`tests/integration/test_diff_tree.lua` (`make test-integration`) covers
`tree_rows` (paths, summaries, `@@` text, ranges), the pure hover/containment
helpers, the rendered buffer lines, the fold options **and the resulting fold
levels**, the initial highlight extmark, hover's `zt` (topline, the source
cursor, the `'scrolloff'` zero/restore), the `<CR>` jump, every forwarded fold
command (`za`/`zA`/`zc`/`zC`/`zo`/`zO` on both row kinds, `zR`/`zM`/`zr` incl. a
count, plus the tree mirror and the no-op repeats), the `ga` hand-off to
`lib.git`, and the toggle-close.
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
  their logic is extracted into `tree_hl_range` / `tree_row_containing` and
  tested directly.
- **`index` commit hashes must be 4–64 hex chars** for the `diff` grammar to
  keep parsing a block; short fake hashes (`index 111..222`) turn the section
  into an ERROR node and drop its hunks. Tests use `1111111..2222222`.
- **Buffer vars before `foldmethod`**: assigning `'foldmethod'` evaluates the
  foldexpr immediately. `open_tree` used to store `vim.b.diff_tree_rows` after
  setting the option, so that first evaluation saw no rows, cached level 0 for
  every line, and — nothing ever edits the tree buffer to invalidate the cache
  — no row folded, in the tree or (once the `z` forwarding existed) anywhere. The rows are now
  stored first; the test asserts `foldlevel()`, not just the option values.
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
