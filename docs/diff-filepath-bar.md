# Inline filepath bars for `diff --git` headers

Each `diff --git a/x b/x` header line in fugitive patch buffers
(`filetype=git`: `:Git diff` / `show` / `log -p`, incl. `:Diff`) is rendered
as a winbar-like bar — `icon path  +N -M` — instead of the raw header. The
buffer text is never modified: the bar is pure extmarks.

## Pipeline

```
fugitive streams output ──► filetype=git buffer
        │                        │
        │              after/ftplugin/git.lua   (FileType + on_lines)
        ▼                        ▼
  buffer lines ──────► lib.Diff.parse_blocks(bufnr)
                               │
              1. treesitter `diff` grammar: `block` nodes + `+`/`-` stats
              2. new path (strip a/ b/ i/ w/ prefix, C-quoting)
              3. mini.icons glyph + hl
                               ▼
                  extmarks in ns "nvim.diff_filepath"
                  virt_text_pos = "overlay", hl_group fg=bg
```

## Mechanism

`lib.diff_filepath.render(bufnr)` clears and re-sets one extmark per block, on
the block's 0-based header row:

- `hl_group = 'DiffFileBar'` with `fg == bg` over the whole line
  (`end_row = row + 1`, `hl_eol = true`) — the raw `diff --git …` text is
  painted in its own background color, i.e. invisible.
- `virt_text` with `virt_text_pos = 'overlay'` draws the bar chunks on top:
  `{icon, mini.icons hl}`, `{path, DiffFileBarPath}`,
  `{summary, DiffFileBarSummary}`.
- Default extmark priority (4096) draws above treesitter's 100, so the
  fg=bg mask wins over syntax/treesitter fg on the raw line.

`end_row = row + 1` (not `end_col = -1`) is deliberate: `end_col = -1`
requires `strict = false` in nvim 0.12, and the `end_row` form is what
treesitter-context's `copy_extmarks` forwards cleanly.

## treesitter-context integration

The namespace is named `nvim.diff_filepath` **on purpose**.
`nvim-treesitter-context` renders its sticky context line in a separate
floating scratch buffer and mirrors source extmarks into it via
`render.copy_extmarks`, which filters to namespaces whose name starts with
`nvim.`:

```lua
for nm, id in pairs(api.nvim_get_namespaces()) do
  if vim.startswith(nm, 'nvim.') then namespaces[id] = true end
end
```

So the single in-buffer extmark shows up both on the header line and in the
context window with no treesitter-context fork. The `diff` context query
captures `(block)` clamped to its first line, so the bar maps to row 0 of the
context buffer.

## Data

`lib.Diff.parse_blocks(bufnr)` is the shared parse behind both this feature
and the `:Diff` quickfix (`M.parse_items`). Each block:

```
{ row, lnum, path, icon, icon_hl, adds, dels, summary }
```

## Highlight groups

Defined in `after/plugin/diff-colors.lua` (`apply()`, so re-applied on
ColorScheme / background change), colors from `colors.diff` in
`lua/colors.lua`:

- `DiffFileBar` — `bg = header`, `fg = header` (the invisible mask)
- `DiffFileBarPath` — `bg = header`, `fg = header_fg`
- `DiffFileBarSummary` — `bg = header`, `fg = header_summary_fg`

`header` matches tufte's `bg2` (= `TreesitterContext` bg) so the bar blends
into treesitter-context's floating window.

## Trigger

`after/ftplugin/git.lua` attaches an `on_lines` watcher (coalesced to one
`vim.schedule` per tick) because fugitive sets `filetype=git` before its job
streams the diff — same timing as the old word-diff emphasis
(docs/diff-emph.md, deprecated).

## Testing

- Integration: `tests/integration/test_diff_filepath.lua` — buffer text
  unchanged; extmarks carry the expected `virt_text` chunks, positions, and
  highlight groups.
- The treesitter-context copy behavior is pinned by the namespace-name filter
  (the `nvim.` prefix), verified headless against the real plugin's
  `render.open` during development.
