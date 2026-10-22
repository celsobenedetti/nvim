# Org heading focus ("narrow" for one subtree)

`:OrgFocus` / `<leader>of` renders the headline under the cursor (or the
headline picked from fzf via `:OrgFocusSearch` / `<leader>oF`) alone in the
current window; on an already-focused buffer it goes back to the real headline
in the file. Edits land back in the org file, which stays the source of truth.
Implementation: `lua/lib/org_focus.lua`, wired from
`lua/plugins/secondary/orgmode.lua`.

## Research: no native narrowing

Neovim has no narrowing feature (`:h folds` only hides lines *inside* the
buffer: each folded region still costs one screen line, so it is not
exclusive), and neither does nvim-orgmode. Two candidate shortcuts were
rejected:

- **Folds only** — a messy file still shows one filler line per folded region
  and the cursor can walk into the hidden text.
- **A read-only rendered copy** — no write path, so not "editable focus".

What nvim-orgmode does give us is the exact subtree range without writing a
parser: `OrgApiHeadline.position.start_line/end_line`
(`Range.from_node(headline_node:parent())` in `files/elements/range.lua`;
`end_line` is the last line of the whole subtree, children included — verified
against a file with a drawer, table, src block and nested headings).

## Design: copy buffer + splice on write

1. `M.focus(path, start, end)` copies the range into a new buffer with
   `buftype=acwrite` (idiomatic Vim "I write it myself" buffer, `:h acwrite`)
   and names it `orgfocus://<path>#<start>` so it never collides with the real
   file. `filetype=org` → highlighting, treesitter, todo cycling and the
   org ftplugin keep working.
2. `BufWriteCmd` splices the buffer's lines back into the *source buffer* with
   `nvim_buf_set_lines(src, start-1, end_, ...)` and then writes that buffer.
   Nothing outside the range is touched, so a stale copy can never clobber the
   rest of the file, and the splice is a single undo step in the source buffer.
   The stored `end_` is updated to the new line count, so a subtree that grew or
   shrank keeps syncing to the right range.
3. `BufReadCmd` (`:e!` in the focus buffer) re-reads the range — the read side
   of the sync. No timers, no polling, no file watching.
4. Guard, one string comparison, non-destructive (the focus buffer stays
   modified, nothing is written): if the source range no longer equals what we
   last synced, the subtree changed under us (`:w` in the source, a refile, an
   action) → refuse. The comparison is on the *range only*, so dirty lines
   outside the subtree never block a write. `:e!` resyncs instead of refusing.
   `f.end_` is re-read from a fresh parse (`orgmode.api.load(path).headlines`)
   whenever the subtree is pulled, because an org action can add or remove
   lines inside it.
5. `OrgFocus` (`<leader>of`) on a focus buffer writes it, then shows the source
   buffer with the cursor on the headline — the inverse of focusing. Focusing
   the same headline again reuses its buffer: unsaved focus edits are flushed
   into the source, then the range is pulled back, so neither side goes stale.

### Org actions inside a focus buffer

Org resolves "current file" as `nvim_buf_get_name(0)`
(`utils.current_file_path`) and the headline from the cursor line, so `t`
(todo state) died with `Current file is not a valid org file`, and the cursor
line meant something else anyway. Every org keymap is
`<cmd>lua require("orgmode").action("<name>")<CR>`
(`config/mappings/map_entry.lua`), so `M.focus` wraps
`require('orgmode').action` once: while the current buffer is a focus buffer it
(a) splices unsaved focus edits into the source, (b) swaps the window to the
source buffer with the cursor at `start + line - 1`, (c) runs the action,
(d) swaps back, restores the cursor and pulls the range again — so todo state,
tags, priority, notes, clocks, `insert_heading` all edit the right lines.
The restore is skipped when the action navigated away (`open_at_point`), so it
does not steal the jump.

No autocommand on `TextChanged`: syncing per keystroke would need a line diff
and a write per change. `:w` is the sync, exactly like the real file — and
`state.pi.launch_task`'s "write every modified org buffer" already flushes a
dirty focus buffer through the same `BufWriteCmd`.

## Limitations

- Interception covers `orgmode.action` (all org keymaps), not org *commands*:
  `:Org agenda`, capture and `lib.org_fzf.refile_heading` (`R`) still resolve
  the real path themselves and do not work from inside a focus buffer. `R`
  warns "no headline under the cursor"; use the source buffer for those.
- Text objects (`orgmode.org.text_objects.*`) bypass `action` and still see the
  focus buffer's own text.
- The headline keeps its original level, so a `**` subtree renders with two
  stars. Deliberate: re-leveling would fight `org_startup_indented` and the
  indent that the subtree's body already carries.
- Focusing a subtree whose range extends past the headline (children) is the
  normal case; a subtree is `headline + children` by definition. Use
  `:OrgFocus` on the *parent* to exclude a child.
- The focus buffer is unlisted and has no swap/undo file; it is a view, not a
  document. Closing it (`:bd`) loses nothing that was written.

## Tests

`tests/integration/test_org_focus.lua` (real nvim, `make test-integration`)
covers: subtree copy, write splicing (add a line, rename the headline, keep the
outside untouched), `:e!` reload and resync, changed-subtree write abort, going
back to the source headline with `OrgFocus`, and a `todo_next_state` action
landing on the source headline and being persisted by `:w`.
