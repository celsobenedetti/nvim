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
- **hunk** (indented two spaces under its block): a compact `+N -M` delta
  summary, like the block row's.

Each row carries `lnum` (1-based jump target) and `range` (0-based node span,
used for containment and hover highlight).

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
- **`]` / `[` / `.` / `,`** — next/previous hunk and next/previous file,
  navigating the tree itself (same keys and count semantics as
  `after/ftplugin/git.lua`); each move re-runs the hover preview.
- **`q`** — closes the tree.
- **Bidirectional** — `CursorMoved` in the diff buffer moves the tree cursor
  to the deepest row (hunk over block) containing the source cursor.
- **Fold** — `foldmethod=expr` + `lib.Diff.tree_foldexpr()`: a block is a fold
  header (`>1`) when it has hunks, hunks sit inside it (`1`). `zc`/`zo` on a
  block folds its hunks; blocks without hunks (binary/rename) don't fold.

## Lifecycle

`open_tree` records the tree window and an augroup on the source buffer
(`vim.b.diff_tree_win` / `diff_tree_group`). The tree closes (and the group is
deleted) on: `q`, a second `:DiffTree`, or `BufHidden`/`BufUnload` of the
source buffer. Leaving the tree clears the hover highlight.

## Testing

`tests/integration/test_diff_tree.lua` (`make test-integration`) covers
`tree_rows` (paths, `+N -M` summaries, ranges), the pure hover/containment
helpers, the rendered buffer lines, the fold options, the initial highlight
extmark, the `<CR>` jump, the `]`/`[`/`,`/`.` section navigation, and the
toggle-close.

## Gotchas

- **`CursorMoved` never fires under `--headless`** (no UI). The hover and
  bidirectional autocmds can't be driven by feeding cursor moves in tests;
  their logic is extracted into `tree_hl_range` / `tree_row_containing` and
  tested directly.
- **`index` commit hashes must be 4–64 hex chars** for the `diff` grammar to
  keep parsing a block; short fake hashes (`index 111..222`) turn the section
  into an ERROR node and drop its hunks. Tests use `1111111..2222222`.
- **Deletions** emit `+++ /dev/null`; `block_path` treats that as "no new
  path" and falls back to the `diff --git` command line (the pre-existing
  quickfix builder did not, and would label a deleted file `dev/null`).
