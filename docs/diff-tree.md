# Diff tree sidebar (`:DiffTree`)

An InspectTree-like outline of a `filetype=git` diff buffer, in a left-side
split. It shows only the `diff` grammar's two navigable sections — per-file
`block`s and their `hunk`s — and reuses `:InspectTree`'s interaction model:
hovering a row previews/highlights the section in the diff buffer, `<CR>`
jumps there, and the diff buffer's own cursor keeps the tree in sync.

## Surface

- `:DiffTree` (any buffer that parses as `diff`) — see `after/plugin/Diff.lua`.
- `glt` in `filetype=git` patch buffers — see `after/ftplugin/git.lua`.
- Both call `lib.Diff.open_tree()`, which toggles: a second call closes the tree.

The git→diff treesitter alias (`after/plugin/autocmds.lua`, see
`docs/ts-git-diff-alias.md`) makes fugitive patch buffers parse with the
`diff` grammar, so `:DiffTree` works on `:Diff`, `:Git diff/show/log -p`.

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
  range. The source window scrolls to reveal the section via
  `winrestview({ topline = … })`, which moves the view **without moving the
  cursor** (so hover ≠ jump).
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
- **`za`** — toggles the fold of the section **in the diff buffer**: a file row
  folds its whole `diff --git` block, a hunk row its `@@` section. Uses the
  range form (`:{lnum}foldclose` / `foldopen`), which acts on a line without
  moving the diff window's cursor. File rows mirror the new state onto the
  tree's own fold, so a collapsed file hides its hunk rows here too. Other fold
  actions (`zc`/`zo`/`zR`…) still act on the tree only.
- **Bidirectional** — `CursorMoved` in the diff buffer moves the tree cursor
  to the deepest row (hunk over block) containing the source cursor.
- **Fold (the tree's own)** — `foldmethod=expr` +
  `lib.Diff.tree_foldexpr()`: a block is a fold header (`>1`) when it has
  hunks, hunks sit inside it (`1`). `zc`/`zo` on a block folds its hunks;
  blocks without hunks (binary/rename) don't fold.

## Lifecycle

`open_tree` records the tree window and an augroup on the source buffer
(`vim.b.diff_tree_win` / `diff_tree_group`). The tree closes (and the group is
deleted) on: `q`, a second `:DiffTree`, or `BufHidden`/`BufUnload` of the
source buffer. Leaving the tree clears the hover highlight.

## Testing

`tests/integration/test_diff_tree.lua` (`make test-integration`) covers
`tree_rows` (paths, summaries, `@@` text, ranges), the pure hover/containment
helpers, the rendered buffer lines, the fold options **and the resulting fold
levels**, the initial highlight extmark, the `<CR>` jump, `za` (both row kinds,
plus the tree mirror), the `ga` hand-off to `lib.git`, and the toggle-close.
`lib.git.add` itself is covered against a throwaway repo in
`tests/integration/test_diff_ga.lua`.

## Gotchas

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
  — no row folded, in the tree or (once `za` existed) anywhere. The rows are now
  stored first; the test asserts `foldlevel()`, not just the option values.
- **Folds in the diff window**: `za` needs real folds there, so
  `after/ftplugin/git.lua` sets `foldmethod=expr` +
  `v:lua.vim.treesitter.foldexpr()` per patch window (the diff grammar's
  `folds.scm` captures `block`, `hunks`, `hunk`). The global default is
  `indent`, and the treesitter plugin only stamps expr folding on whichever
  window is current when it configures itself.
- **Deletions** emit `+++ /dev/null`; `block_path` treats that as "no new
  path" and falls back to the `diff --git` command line (the pre-existing
  quickfix builder did not, and would label a deleted file `dev/null`).
