# Fold lines and render-markdown decoration chunks

## Symptom

With treesitter folding on headings and lists plus render-markdown.nvim, a
closed fold's first line shows a paper-white sliver behind the small
decoration exactly where the heading icon (`󰲣` for `##`) or the list marker
(`1.`) sits, while the rest of the line is `Folded` tan.

## Why

On a closed fold, `Folded` is the *bottom* layer; everything else paints over
it. The measured precedence on a folded line, highest first:

1. overlay `virt_text` chunks (render-markdown's decorations) — unbeatable
2. `line_hl_group` (the `FoldFlatFolded` stamp from `lib.fold_hl`, prio 65534)
3. range `hl_group` / `hl_eol`, syntax, treesitter
4. `Folded`

`lib.fold_hl` fixes layers 2–4. Layer 1 cannot be fixed there: virt text is
painted after every line background, so no stamp outranks it.

Two independent facts about render-markdown's chunks make the sliver:

- The default `hl_mode` for `virt_text` extmarks is `replace`, not `combine`.
  A chunk whose highlight is fg-only (the list marker's
  `RenderMarkdownBullet`) *replaces* the underlying cell's highlight, and an
  unset background falls back to the **buffer default** (paper `c.bg`), not
  the surface behind the cell.
- The heading icon chunk carries its own background group,
  `RenderMarkdownH*Bg` (tufte pairs it with paper), which survives even
  `combine` (an explicitly-set attribute wins).

## The fix

Both levers live at chunk-build time, in
`lua/lib/render_markdown_fold.lua`, applied from the render-markdown plugin
spec (`lua/plugins/secondary/markdown.lua`):

1. Every `virt_text` mark opts into `hl_mode = 'combine'` unless it already
   sets one (the plugin's own checkboxes/wiki links already do). fg-only
   chunks — list markers, dashes — then keep the background they sit on.
2. Array-form chunk highlights — only the heading icon's `{ fg, bg }` pair,
   per `render/markdown/heading.lua` — drop trailing groups that resolve to a
   background. The icon keeps its fg group (`RenderMarkdownHx`) and inherits
   the surface; the *band* still uses `RenderMarkdownHxBg` (paper) and is
   untouched.

### Why not fix it in tufte's groups

`RenderMarkdownHxBg = { bg = c.bg }` (tufte groups/render-markdown.lua:30) is
only half the story. The band and the icon share that group, so the group
cannot be both "paper for the unfolded band" and "transparent on folds" at
once. And a bg-less tufte definition cannot survive anyway:
render-markdown re-links its default groups with `default = true`, and nvim
only treats a group with a *real* fg/bg/attr/link as "already has settings"
(src/nvim/highlight_group.c, `hl_has_settings`) — `{ bg = 'NONE' }` or `{}`
are not settings, so the plugin's pastel DiffText/DiffAdd defaults come back.

## Verification

- `make test-integration` → `tests/integration/test_render_markdown_fold.lua`
  asserts the chunk marks from a real render carry `combine` and a stripped
  icon highlight.
- Pixel check on a folded heading and folded list line: the decoration
  cells, the sign, and the rest of the line all share the `Folded`
  background.

## Related environment notes

`test_tab.lua` and `test_tabline_float_flicker.lua` fail in headless
luajit/nvim because their terminal-label expectations need a real terminal
with working title updates — they fail identically on a clean tree and are
unrelated to folding or rendering.
