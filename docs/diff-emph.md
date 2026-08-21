# Intra-line diff emphasis for fugitive patch buffers

Delta-style "word diff" for `:Git log -p`, `:Git show`, `:Git diff` output:
whole +/- lines already get `diffAdded`/`diffRemoved` washes from
`after/plugin/diff-colors.lua`; this adds emphasis on just the changed words
inside those lines (`PlusEmph`/`MinusEmph`, mapped to delta's
plus-emph/minus-emph styles).

## Pieces

- `lua/lib/diff_emph.lua` - pure planner. Scans buffer lines, pairs each
  maximal `-` run with its following `+` run, diffs the two token streams
  with `vim.text.diff(..., { result_type = 'indices' })`, and returns byte
  ranges to emphasize. Adjacent changed tokens (gap <= 1 byte) merge into
  one span. The sequence diff is an injected dependency so unit tests can
  swap in a naive LCS reference.
- `tests/lib/test_diff_emph.lua` - luajit unit tests (mock vim bits, inject
  naive LCS as reference implementation).
- `after/ftplugin/git.lua` - wiring. Runs on FileType git, gates on actual
  hunk headers (`^@@ `) so metadata-only buffers are untouched, applies
  extmarks in namespace `diff_emph`.
- `after/plugin/diff-colors.lua` - defines `PlusEmph`/`MinusEmph` from the
  palette's `add_char`/`delete_char` (bg + fg, cranked past delta's subtle
  default like the gitsigns inline groups).

## Why the ftplugin watches on_lines

Fugitive types the output buffer (`filetype=git`) BEFORE its job streams
content into it - at FileType time the buffer is empty. A once-only pass
sees nothing. So the ftplugin schedules a replan and re-runs it coalesced
per event-loop tick via `nvim_buf_attach(on_lines=...)`. Replan is
O(buffer); 20k-line logs plan fine because xdiff does the heavy lifting in C.

## Gotchas discovered (integration testing)

1. **rtp after/ entries are explicit trailing entries.** The default rtp
   lists e.g. `/home/me/.config/nvim/after` as its own entry at the end.
   Prepending a repo dir (`set rtp^=.`) does NOT make `repo/after`
   discoverable - you must also `set rtp+=repo/after`. This is why
   AGENTS.md's stock integration recipe resolves `lib.*` but not
   `after/ftplugin`.
2. **`filetype plugin on` is required under `-u NONE`.** Setting
   `filetype=git` fires the FileType event, but nothing sources ftplugins
   unless `$VIMRUNTIME/ftplugin.vim` was loaded (its `FileType *` autocmd
   calls LoadFTPlugin). Production configs enable this by default.
3. **fugitive `:Git` output arrives async** even for read-only commands -
   headless assertions need `sleep N` (or vim.wait) before checking buffer
   contents/extmarks. Note `-l` mode never delivers fugitive job output;
   use `-c ... -c sleep -c qa!` chains instead.
