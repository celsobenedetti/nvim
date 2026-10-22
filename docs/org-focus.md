# Org heading focus ("narrow" for one subtree)

`:OrgFocus` / `<leader>of` renders the headline under the cursor (or the
headline picked from fzf via `:OrgFocusSearch` / `<leader>oF`) alone in the
current window. Edits land back in the org file, which stays the source of
truth. Implementation: `lua/lib/org_focus.lua`, wired from
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
4. Guards, both one comparison and both non-destructive (the buffer stays
   modified, nothing is written):
   - source buffer has unsaved changes → refuse (`:w` in the source first; this
     is the case where a blind splice would drop someone else's edit),
   - the headline line at `start` no longer equals the one we last synced →
     refuse (source moved/reordered; `:e!` re-syncs).

No autocommand on `TextChanged`: syncing per keystroke would need a line diff
and a write per change. `:w` is the sync, exactly like the real file — and
`state.pi.launch_task`'s "write every modified org buffer" already flushes a
dirty focus buffer through the same `BufWriteCmd`.

## Limitations

- `OrgApi.current()` resolves the focus buffer's name (`orgfocus://…`) to no
  file, so commands that need the *real* path (refile, agenda from point,
  `:OrgDo`) do not work from inside a focus buffer. Work from the source buffer,
  or reload the focus buffer's mapping later if this matters.
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
outside untouched), `:e!` reload, stale-source abort, unsaved-source abort.
