# Custom quickfix rendering with 'quickfixtextfunc'

How `:DiffQf`'s pretty, aligned quickfix table works — and the native nvim
hook behind it. Knowledge captured from implementing lib.Diff's qf rows.
(`:DiffQf` was `:Diff` until the DiffTree sidebar became the default index;
`docs/diff-tree.md`.)

## The core idea: data is separate from display

A quickfix entry is a record with (among others) these fields
(`getqflist()`):

- **Jump target**: `bufnr` + `lnum` (or `filename`/`lnum`, plus optional
  `col`/`pattern`). `<CR>`, `:cc`, `:cn`, the jumplist — all driven by
  these fields.
- **Display label**: `text`. Rendered in the qf window and in the
  `(1 of N): text` jump message. Never consulted for the jump.

So "a label that doesn't affect position" is literally the `text` field —
put anything there (`path +N -M`, icons, …) and the jump target is
untouched.

## The problem with the default renderer

The qf window line is formatted by `qf_buf_add_line()` in
`src/nvim/quickfix.c` as:

```
<file or module>| <lnum or pattern>| <text>
```

Two limitations for custom layouts:

1. The `file|lnum|` prefix is fixed (and the file part is the buffer's
   name — one buffer per list, so it can't vary per row).
2. When a filename or lnum is present, the text is passed through
   `skipwhite()` (`gap->ga_len > 3 ? skipwhite(qfp->qf_text) : …`,
   quickfix.c:4295). **Leading whitespace is stripped**, so you cannot
   pad the text to align columns against the variable-width `|1|` vs
   `|186|` prefix.

## The hook: 'quickfixtextfunc'

`'quickfixtextfunc'` (see `:help quickfixtextfunc`, quickfix.txt:2399)
replaces the renderer. It can be set:

- **Per list** — as an attribute of the `setqflist()`/`setloclist()` dict:
  `setqflist([], ' ', {'quickfixtextfunc': 'v:lua.lib.Diff.qf_line'})`.
  This overrides the global option and only lives while that list is
  current.
- **Globally** — `set quickfixtextfunc=…` applies to every list.

### Contract

Called with a dict `{quickfix, winid, id, start_idx, end_idx}` and must
return a list of strings, **one per entry from `start_idx` to `end_idx`**
(the window may only redraw a range). The function reads the entries with
`getqflist({'id': info.id, 'items': 1})`.

- An empty string for an entry → **the default format is used for that
  entry**.
- An empty list → default format for all entries.

The callback can be a function name, funcref, lambda, or a
`v:lua.Module.func` string (verified working; the name is evaluated in
the Lua global environment, so the module must be reachable as
`_G.<path>`).

If a returned string is non-empty, it becomes the **entire** buffer line
— no `file|lnum|` prefix, no `skipwhite`. This is what makes perfect
column alignment possible.

## How lib.Diff uses it

`lua/lib/Diff.lua`:

1. `parse_items()` computes rows with display-width padding
   (`vim.fn.strwidth`, so multibyte icons/paths stay aligned):
   right-aligned `lnum` column, `mini.icons` glyph + path padded to the
   widest label, aligned `+N -M` summary. The padded string is stored in
   the item's `text`.
2. `open()` sets the list with `quickfixtextfunc = 'v:lua.lib.Diff.qf_line'`.
3. `M.qf_line(info)` maps `start_idx..end_idx` → the items' `text`,
   returned verbatim.

The qf window line N still corresponds to entry N, so the `<CR>`
mapping (`install_qf_jump`) keeps working: it reads `line('.')` and runs
`:cc <nr>` against the real `bufnr`/`lnum`.

## Gotchas

- **`skipwhite` eats leading spaces** in the default rendering
  (quickfix.c:4295) — the reason leading padding failed before
  `quickfixtextfunc` was used.
- **Never return `''`** from the renderer for an entry you want to fully
  control — it silently falls back to the default format.
- **List-scoped lifetime**: `:grep` (or any other tool that replaces the
  list) drops the `quickfixtextfunc` attribute and renders natively
  again. That scoping is deliberate.
- **The renderer re-reads the list by `id`** — always use
  `getqflist({ id = info.id, items = 1 })`, not the current list (the
  current list may differ inside the callback).
- **`getqflist()` with no args returns the list *number***, not a dict;
  and a bare `{}` converts to an empty *list* (E715). Use
  `getqflist({ items = 1, idx = 1, title = 1 })`.
- nvim's `require` prefers `runtimepath/lua/` over `package.path`
  (AGENTS.md): a `v:lua.` callback resolves through rtp, so tests that
  exercise it must prepend the repo to `'runtimepath'`, not just
  `package.path`.
- One qf buffer line = one entry, always — `line('.')` is a safe entry
  index even with a custom renderer.

## Winbar for the qf window

The qf window's winbar leads with the qf buffer's own (special) name
(`[Quickfix List]`, or `[Location List]` for loclists — buf_spname in
buffer.c, not exposed by nvim_buf_get_name), then ` > ` and the
breadcrumb tail: `<icon> Diff <args>` for `:DiffQf` lists, `<icon> git log`
for the fugitive `:Gclog` stamp.

`:DiffQf` creates its list with `setqflist()`, which does **not** fire
`QuickFixCmdPost`, so the Gclog-style stamping hook never runs for it.
Instead:

- lib.Diff keeps a registry `qf list id → winbar text`
  (`M.record_winbar` in `open_qf()`, `M.winbar_text` lookup).
- `get_winbar()` adds a quickfix-buffer branch: for `buftype == 'quickfix'`
  it reads the *current* list id (`getqflist({ id = 0 }).id`) and
  renders `name > tail`, or just the buffer name when there's no tail.

Resolving by list id at render time is self-cleaning — no stamp to clear:
a new list (grep, another `:DiffQf`) has a new id and simply doesn't match.
Because each `setqflist` pushes onto the qf stack (old ids stay valid),
`:colder` back to a previous `:DiffQf` list keeps its bar.

## Testing

`tests/integration/test_Diff.lua` asserts the exact padded row strings
from `parse_items()` and that `quickfixtextfunc` renders them verbatim
(no `file|lnum|` prefix, leading padding preserved).
