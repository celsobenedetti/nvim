# Diff tree sidebar (`:DiffTree`)

An InspectTree-like outline of a `filetype=git` diff buffer, in a left-side
split, in three levels: a **directory group header** per parent directory, the
**files** changed in it, and each file's **hunks**. The lower two are the `diff`
grammar's navigable sections (`block`, `hunk`); the group headers are ours, so
files sharing a parent directory sit together (mini.icons puts a glyph in
front of each basename; not shown here):

```
lua/lib/
 M Diff.lua   +407 -168
   @@ -496,6 +496,7 @@
   @@ -604,11 +612,7 @@
 A git.lua   +86
lua/plugins/
 M treesitter.lua   +6 -1
```

Interaction follows `:InspectTree`: hovering a row scrolls the section to the
top of the diff buffer, `<CR>` jumps there, and the diff buffer's own cursor
keeps the tree in sync.

## Surface

- `:Diff [rev] [rev2]` — the default index for a new diff tab: the patch on
  the right, this tree on the left and focused (`lib.Diff.open`). The tab is
  named after what was asked for — `Diff HEAD~5..HEAD`, `Diff (working tree)`
  — the same label as the quickfix list's title and winbar. `patch_tab` queues
  it with `lib.tab.set_next_name` and the git-tab autocmd
  (`after/plugin/autocmds.lua`) applies it; that autocmd looks for a git buffer
  in **any** window of the new tab, since `:Diff` leaves the sidebar focused
  (`filetype=diff-tree`) and `:DiffQf` the quickfix list. `:DiffQf` is
  the older quickfix-of-files flavour (`lib.Diff.open_qf`); both share
  `patch_tab()`, which opens the fugitive tab and waits for its job. See
  `after/plugin/Diff.lua`.
- `:DiffTree` (any buffer that parses as `diff`) — see `after/plugin/Diff.lua`.
- `glt` and `s` in `filetype=git` patch buffers — see `after/ftplugin/git.lua`.
  `s` is the quick toggle and is bound in the tree buffer too, so one key opens
  and closes the sidebar from either side. Being buffer-local it shadows
  flash.nvim's `s` only inside patch buffers (`S` and `f`/`t` are untouched),
  and normal-mode `s` has nothing to substitute in a `buftype=nowrite` buffer
  anyway.
- All of these call `lib.Diff.open_tree()`, which toggles: a second call closes
  the tree.

The sidebar opens 30 columns wide the first time, and after that at **the share
of `'columns'` it had when it was last closed** for that buffer (`tree_width` /
`record_tree_ratio`) — so toggling it off and on keeps a `<C-w>>` resize, and a
terminal resized in between keeps the proportion rather than the column count.
It never opens so wide that the diff window is left under 10 columns. Rows are
rendered for the actual width, which is what decides how much room a long name
gets before it is truncated. The window carries no number column (`nonumber` +
`norelativenumber`).

The git→diff treesitter alias (`after/plugin/autocmds.lua`, see
`docs/ts-git-diff-alias.md`) makes fugitive patch buffers parse with the
`diff` grammar, so the tree works on `:Diff`, `:Git diff/show/log -p`.

## Rows

`lib.Diff.tree_rows(bufnr)` walks the parse tree and returns one flat list of
three row kinds:

- **dir** (column 0): the parent directory with its trailing slash (`lua/lib/`,
  `./` for repo-root files). Emitted once per directory, in first-appearance
  order, with every file of that directory underneath it.
- **block** (a file, one space in): ` <status> <icon> <name>   <+N -M>` — the
  **basename** only, since the directory is the header above it. `status` is
  `A`/`D`/`R`/`M` (added / deleted / renamed / modified), read from git's
  `new file mode` / `deleted file mode` / `rename from|to` line and falling
  back to the `/dev/null` side of the `---`/`+++` pair. The path itself comes
  from the `+++ b/x` line (falling back to the `diff --git` command's last path
  token, `/dev/null`-aware for deletions). The `+N -M` summary sits **three
  spaces behind the name** — right-aligning it at the sidebar's edge parked
  every short name's summary a screen away from it. The name is truncated with
  `…` only when the two together would overflow, so the summary stays
  readable.
- **hunk** (indented under its file): the full `@@ -a,b +c,d @@` line,
  including git's trailing function/class heading — the `location` node's text,
  whose range the row keeps as `location` for the hover highlight.

Grouping is by directory **key**, not by consecutive runs: git's path sort
interleaves them (`a/b.txt`, `a/bb/z.txt`, `a/c.txt`), which would otherwise
open `a/` twice. Files pulled up to their group keep their own `lnum`, so
nothing about the jump targets changes.

Every row carries `lnum` (1-based jump target) and `range` (0-based node span,
used for containment); a dir row borrows both from its first file, which is
what hover and `<CR>` act on there. Hunk rows
also carry their block's `path`, so file-scoped actions (`ga`) work from any
row kind but a dir, plus `location`, the span hover highlights. Dir rows instead carry `blocks`, the header line of every
file in the group, so one fold command can fold all of them.

Colours come from extmarks in the `lib.diff.tree` namespace: the group header
as `Directory`, the status letter as `Added`/`Removed`/`Changed`, the
mini.icons glyph in its own group, hunk rows dimmed as `Comment`.

## Interaction (mirrors `:InspectTree`)

- **Hover** — `CursorMoved` in the tree (`M.tree_focus`) does three things to
  the diff window, and never moves focus out of the tree; only `<CR>` moves
  you. A dir row acts on its first file, so hovering a group previews where it
  starts. **Folds are left exactly as they are**: hovering is a scroll, not an
  edit of the fold state, so a closed section stays closed until `zo`/`zO` on
  the row opens it.
  1. **park it on top** — `zt`, on every hover and not only when the section is
     off-screen. It **respects the diff window's `'scrolloff'`**: the section
     lands that many lines below the top edge, keeping the usual margin of
     context. That needs the diff window's cursor to move there too (see the
     gotcha below).
  2. **highlight the section** — a block row re-emits lib.diff_filepath's
     overlay bar on its hover palette (`DiffFileBarHover*`); the header line's
     visible pixels belong to that extmark, whose `virt_text` chunks no second
     extmark can restyle, so the bar has to carry the palette itself. A dir row
     previews its first file, so it lights up that file's bar. A hunk row
     highlights its `@@` header line — the `location` node's exact span (git's
     trailing function heading included, the node covers it) — with a
     `DiffHunkHover` extmark in the `lib.diff.tree.hover` namespace. That one
     is plain buffer text, so the group is background-only and the treesitter
     foreground of the `@@` line survives underneath. Both hover surfaces take
     `Visual`'s background (`after/plugin/diff-colors.lua`), so the two row
     kinds read the same. One mark at a time: every hover clears the namespace
     first, and leaving the tree (`BufLeave`) or closing it drops both the
     highlight and the bar hover.
  3. **refresh the sticky context** — nvim-treesitter-context for the *diff*
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
- **`q`** / **`s`** — close the tree (`s` is the toggle from the diff side).
- **`J`** / **`K`** — scroll the diff window down / up without leaving the
  sidebar: one line per press, `v:count` lines with a count (`5J`), and the
  sticky context recomputed afterwards, same as on hover. `normal! <C-e>` runs
  through `nvim_win_call`, so the diff window is briefly current and
  `'scrolloff'` can drag its cursor along — see the sync gotcha below.
- **`ga`** — stages the row's file via `lib.git.add` (same flow as
  `ga` in a normal buffer or in the patch buffer — `Git add -p` for unstaged
  changes, plain `git add` when untracked). Focus moves to the diff window
  first, so fugitive's interactive split doesn't open inside the 30-column
  sidebar. From a hunk row it stages the whole file (rows carry their block's
  path); on a dir row it does nothing — group headers carry no path, and
  staging a whole directory is not what `ga` means anywhere else.
- **`z` fold commands** — fold the **diff buffer**, mirrored onto the tree.
  `lib.Diff.tree_fold(tree_buf, key)` drives all of them from one spec table
  (`TREE_FOLD_ACTIONS`):
  - *line-scoped* `za` `zA` `zc` `zC` `zo` `zO` — act on the row's section: a
    file row folds its whole `diff --git` block, a hunk row its `@@` section,
    and a **dir row every block in its group** (the diff buffer has no
    directory level of its own, so the command is sent once per member file,
    and the direction comes from the tree's own fold — that is what `za`
    toggles there).
    `toggle` (`za`/`zA`) reads the current state, the capitals pass `!` for the
    recursive form. Sent as the range form (`:{lnum}foldclose`), which acts on
    a line **without moving the diff window's cursor** — unlike `normal! zc`.
    Note the native scoping: a command only touches folds containing that line,
    so `zC` from a *hunk* row is what closes the enclosing block.
    Dir and file rows mirror the new state onto their own fold here, so a
    collapsed directory hides its files and a collapsed file its hunk rows;
    hunk rows have no tree fold to mirror. The mirror only acts when the row's
    fold isn't already in that state (see the `:foldclose` gotcha below).
  - *window-wide* `zR` `zM` `zr` `zm` — only move the window's `'foldlevel'`,
    so they are cursor-independent and get forwarded verbatim (with a count:
    `3zm`), then re-run in the tree window. The tree simply has one level more
    than the diff: `zM` collapses it to one row per **directory** (the diff to
    one line per file), `zr` from there reveals the file rows, `zR` expands
    everything again.
  - not forwarded (act on the tree only): `zv`, `zx`/`zX`, `zn`/`zN`/`zi`, and
    the `zj`/`zk` motions. Folding in the diff buffer itself is not mirrored
    back onto the tree.
  - a row with no fold at all (binary/rename block, or folds off) notifies
    once; a repeated `zo`/`zc` in the same direction is a silent no-op (that is
    an `E490` from `:foldopen`/`:foldclose`).
- **Bidirectional** — `CursorMoved` in the diff buffer moves the tree cursor
  to the deepest row (hunk over block) containing the source cursor.
- **Fold (the tree's own)** — `foldmethod=expr` +
  `lib.Diff.tree_foldexpr()`, three levels mirroring the rows: a dir header
  opens level 1, a file row opens level 2 when it has hunks, and hunk rows sit
  at level 2. So `zc` on a directory hides its whole subtree, `zc` on a file
  hides its hunks, and `'foldlevel'` 0/1/2 gives dirs / dirs+files /
  everything. A file without hunks (binary/rename) is a plain line inside its
  group.

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
`tree_rows` (the dir/file/hunk shape, paths, statuses, summaries, `@@` text,
ranges, a group's `blocks`), `tree_row_containing`, the rendered buffer lines,
the fold options **and the resulting fold levels**, the default width and
the missing number column, the width restored on reopen, `s` closing the tree, the hovered file's bar (and
that a dir row previews its first file), hover's `zt` (topline with a non-zero
`'scrolloff'`, the source cursor, and that a closed section stays closed), the
hovered hunk's `@@` highlight (its exact span, that only one exists at a time,
and that leaving the tree clears it), `J`/`K` scrolling (with counts, the clamp
at the first line, and that neither focus nor the tree cursor moves), the
source->tree sync ignoring moves made from the tree, the `<CR>` jump, every
forwarded fold command
(`za`/`zA`/`zc`/`zC`/`zo`/`zO` on all three row kinds, `zR`/`zM`/`zr` incl. a
count, plus the tree mirror and the no-op repeats), the `ga` hand-off to
`lib.git`, and the toggle-close. A second fixture covers the grouping itself:
files spread over `./`, `lua/`, `lua/lib/` and `new/`, with `lua/lib/`
interrupted mid-patch, one file of every status, a rename with no hunks, and a
name long enough to be truncated.
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
  `tree_focus` / `tree_row_containing` are called directly, and the sync
  autocmd itself with `nvim_exec_autocmds`.
- **The source→tree sync must ignore its own side effects.** Hover moves the
  diff window's cursor and `J`/`K` let `'scrolloff'` push it; if the sync
  followed those, it would move the tree cursor, hover that row, and `zt` the
  view back — a scroll that snaps home. It therefore acts only on moves made
  while the diff window is the current one, with a `scrolling` flag covering
  the tick `nvim_win_call` makes it current for.
- **`index` commit hashes must be 4–64 hex chars** for the `diff` grammar to
  keep parsing a block; short fake hashes (`index 111..222`) turn the section
  into an ERROR node and drop its hunks. Tests use `1111111..2222222`.
- **Buffer vars before `foldmethod`**: assigning `'foldmethod'` evaluates the
  foldexpr immediately. `open_tree` used to store `vim.b.diff_tree_rows` after
  setting the option, so that first evaluation saw no rows, cached level 0 for
  every line, and — nothing ever edits the tree buffer to invalidate the cache
  — no row folded, in the tree or (once the `z` forwarding existed) anywhere. The rows are now
  stored first; the test asserts `foldlevel()`, not just the option values.
- **`:foldclose` climbs.** On a line whose innermost fold is already closed it
  closes the *enclosing* one — native `zc` behaviour. The tree has a directory
  level the diff buffer hasn't, so a second `zc` on a file row would fold its
  whole group away here while nothing moves there. The mirror therefore only
  runs when the row's own fold isn't already in the wanted state
  (`mirror_fold`).
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
