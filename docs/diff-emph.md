# Intra-line diff emphasis for fugitive patch buffers

<!-- NOTE: deprecated in c8fdd5a9a91ca7cc7f16d172a3225e4f71d92e6b -->

Delta-style "word diff" for `:Git log -p`, `:Git show`, and `:Git diff` output.
Whole +/- lines already get `diffAdded`/`diffRemoved` washes from
`after/plugin/diff-colors.lua` (regex syntax); this feature layers emphasis on
just the _changed words_ inside those lines — delta's plus-emph/minus-emph
styles, here `PlusEmph`/`MinusEmph`.

## Surfaces

Anything fugitive renders as a raw-output buffer with `filetype=git`:
`:Git log -p`, `:Git show <sha>` (incl. the fzf-lua `<CR>` tabs), `:Git
diff`.
Gvimdiff/Gitsigns surfaces use different machinery and already have their own
emph groups in diff-colors.lua.

## Pipeline

```
fugitive streams output ──► filetype=git buffer
        │                        │
        │              after/ftplugin/git.lua   (FileType + on_lines)
        │                        │
        │                 has_patch()?  ^@@ gate
        │                        │
        ▼                        ▼
  buffer lines ──────► lib.diff_emph.plan(lines)
                               │
               1. pair -/+ blocks (state machine)
               2. tokenize to words w/ byte spans
               3. vim.text.diff(token streams) -> hunk indices
               4. map unmatched tokens -> byte ranges, merge spans
                               │
                               ▼
                  extmarks in ns "diff_emph"
                  hl_group = PlusEmph | MinusEmph
```

## Step by step

### 1. Trigger and gating — after/ftplugin/git.lua

Runs whenever the FileType machinery sources ftplugins for `git`. Two guards:

- `b:diff_emph_setup` makes re-sourcing idempotent (filetype resets, refires).
- `has_patch()` requires at least one line starting with `@@`. Metadata-only
  output (`:Git log --name-only`, config listings) shares the filetype but has
  nothing to emphasize.

### 2. Block pairing — `plan()` (lib/diff_emph.lua:99)

Unified format guarantees that within one change segment all deletions precede
all additions. So a linear scan suffices:

- `-x` / `+y` lines append to the current `del_rows` / `add_rows` runs (`---` /
  `+++` prefixes excluded — those are file headers).
- Any other line (context, `@@`, metadata, commit message) calls `flush()`: if
  both runs are non-empty they get diffed against each other, then both reset.

A pure-deletion or pure-insertion run has no counterpart and gets nothing —
matching delta's behavior of only emphasizing _paired_ changes.

### 3. Tokenization — `tokenize()` (line 30)

Each content line (minus its `-`/`+` marker) is split into `%S+` words. Tokens
carry their byte span (`col`, `end_`) so word-level results map back onto the
buffer line. Blank content lines yield zero tokens and simply don't participate
— there is nothing to paint on them.

### 4. Sequence diff — `build()` (line 53)

All tokens of a block are joined with `\n` into one string per side; every token
becomes one "line" of the diff input.
`vim.text.diff(a, b,
{ result_type = 'indices' })` returns hunks
`{start_a, count_a, start_b,
count_b}` over those token-lines (1-based).
Unmatched index ranges = changed words. xdiff runs in C, which is what keeps
replans cheap on big logs.

The diff function is an injected parameter (`plan(lines, difffn)`); production
uses vim.text.diff, unit tests inject a naive LCS reference so the tests pin
down parsing/mapping rather than xdiff behavior.

### 5. Span emission and merging — `emit()` (line 71)

For each hunk, indices walk `del_meta`/`add_meta` (diff-line-index -> byte-span
tables). A guard skips phantom indices when one block is shorter. Consecutive
spans merge when same row, same kind, gap <= 1 byte — adjacent changed words
paint as one blob instead of striped highlights.

### 6. Extmark application — after/ftplugin/git.lua

Regions become extmarks in namespace `diff_emph` with default priority; extmarks
sit above regex syntax, and since `PlusEmph`/`MinusEmph` carry both bg and fg,
emphasized words render exactly like delta's emph styles (palette
`add_char`/`delete_char`, deliberately cranked brighter than delta's subtle
default — same decision as the gitsigns inline groups).

## Why it watches on_lines instead of running once

Fugitive creates the buffer and sets `filetype=git` BEFORE its job streams
output into it — at FileType time the buffer is empty, so a once-only pass would
always be a no-op. The ftplugin instead schedules a replan and re-runs it via
`nvim_buf_attach(on_lines=...)`, coalesced with a `pending` flag so a stream
burst of many chunks costs one plan per event-loop tick, not one per chunk.
Replans are O(buffer): a 20k-line `log -p -n 100` produces ~3.5k marks without
noticeable lag.

## Testing

- Unit: `tests/lib/test_diff_emph.lua` (`luajit`, part of `make test`). Mocks
  the two vim functions used (`list_extend`), injects a naive-LCS reference
  diff, and pins exact regions for: single-word change, unpaired runs, header
  skipping, total rewrites, multi-line pairing, span merging, unequal run sizes,
  context-separated segments, and blank-line regression (blank +/- lines must
  not shift hunk indices).
- Integration: real nvim headless against actual fugitive output — see the
  gotchas below; recipe lives in AGENTS.md.

## Known tradeoffs

- A deleted line whose content literally starts with `--` is indistinguish- able
  from a `--- a/file` header and is skipped (same tradeoff as diff-colors.lua's
  terminal classifier).
- Word granularity includes trailing punctuation (`foo,` vs `foo` differ), like
  delta's default word split.
- Emphasis only pairs del-block followed immediately by add-block; git never
  emits interleaved orders within a segment, so no cases are missed.

## Gotchas discovered (integration testing)

1. **rtp after/ entries are explicit trailing entries.** The default rtp lists
   e.g. `/home/me/.config/nvim/after` as its own entry at the end. Prepending a
   repo dir (`set rtp^=.`) does NOT make `repo/after` discoverable - you must
   also `set rtp+=repo/after`. This is why AGENTS.md's stock integration recipe
   resolves `lib.*` but not `after/ftplugin`.
2. **`filetype plugin on` is required under `-u NONE`.** Setting `filetype=git`
   fires the FileType event, but nothing sources ftplugins unless
   `$VIMRUNTIME/ftplugin.vim` was loaded (its `FileType *` autocmd calls
   LoadFTPlugin). Production configs enable this by default.
3. **fugitive `:Git` output arrives async** even for read-only commands -
   headless assertions need `sleep N` (or vim.wait) before checking buffer
   contents/extmarks. Note `-l` mode never delivers fugitive job output; use
   `-c ... -c sleep -c qa!` chains instead.
