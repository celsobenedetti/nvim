--- render-markdown.nvim paints list markers and heading icons as `virt_text`
--- extmarks. Neovim's default `hl_mode` for virt_text is `replace`: the
--- chunk's highlight replaces the highlight of the cell it covers, and any
--- attribute the chunk leaves unset (a background, for fg-only groups like
--- `RenderMarkdownBullet`) falls back to the *buffer default* background, not
--- the surface behind the cell.
---
--- On a closed fold line that surface is `Folded`. The heading icon chunk
--- additionally carries its own background (tufte's `RenderMarkdownH*Bg`,
--- paper) so its cells stay paper-white while the rest of the line is
--- folded. Either way the folded line ends up with a paper sliver behind
--- `1.` / `󰲣`.
---
--- The plugin already opts some chunks (checkboxes, wiki links) into
--- `hl_mode = 'combine'`; this module extends that to every virt_text mark
--- and drops background groups from array highlights (the heading icon's
--- `{ fg, bg }` pair), so decorations inherit the background they sit on:
--- Normal paper, code `bg2`, or a `Folded` line.
--
-- Fold layer order on a closed fold (highest first):
--   1. overlay virt_text chunks — the only layer that can beat fold_hl's
--      `line_hl_group` stamp (lib.fold_hl), because virt text is painted
--      after every line background
--   2. line_hl_group stamp (FoldFlatFolded, priority 65534, lib.fold_hl)
--   3. range hl_group / hl_eol, syntax / treesitter
--   4. `Folded`
--
-- A chunk therefore shows through as paper on a folded line no matter what
-- the stamp does; the levers are exactly two, both at chunk-build time:
-- the chunk must combine (below) and must not carry its own background.
-- The heading band (`RenderMarkdownH*Bg`) stays paper — tufte defines it
-- that way and the plugin re-links bg-less groups with `default = true`,
-- so the band cannot double as the icon's background; only the icon chunk
-- has its background group stripped.
--- Wrap the marks funnel so every virt_text mark (1) combines its highlight
--- with the text (and background) underneath, and (2) drops trailing
--- highlight groups that define a background when a chunk uses a group array
--- — the heading icon's `{ fg, bg }` pair, where the bg group exists for the
--- unfolded band and must not paint through on folded lines. Marks that
--- already set `hl_mode` explicitly (the plugin's own checkboxes, wiki
--- links, inline links) keep theirs. Call once, after
--- `require('render-markdown').setup()`: renders happen later, on buffer
--- events, and go through this funnel each time.
local function patch_render_markdown_hl_fold()
  local marks = require('render-markdown.lib.marks')
  local add = marks.add
  local function strip_bg(text)
    local hl = text[2]
    if type(hl) ~= 'table' or #hl < 2 then
      return
    end
    -- head_icon chunks are `{ { icon, { fg, bg } } }`; drop any trailing
    -- group that resolves to a background (stops at the first fg group).
    while #hl > 1 and vim.api.nvim_get_hl(0, { name = hl[#hl] }).bg ~= nil do
      hl[#hl] = nil
    end
  end
  marks.add = function(self, config, conceal, start_row, start_col, opts)
    if opts.virt_text then
      opts.hl_mode = opts.hl_mode or 'combine'
      for _, text in ipairs(opts.virt_text) do
        strip_bg(text)
      end
    end
    return add(self, config, conceal, start_row, start_col, opts)
  end
end

return {
  -- lazy.nvim
  {
    'antonk52/markdowny.nvim',
    ft = { 'markdown' },
    config = function()
      require('markdowny').setup()
    end,
  },
  {
    'MeanderingProgrammer/render-markdown.nvim',
    dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-mini/mini.nvim' }, -- if you use the mini.nvim suite
    -- dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-mini/mini.icons' },        -- if you use standalone mini plugins
    -- dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-tree/nvim-web-devicons' }, -- if you prefer nvim-web-devicons
    ---@module 'render-markdown'
    ---@type render.md.UserConfig
    opts = {},
    ft = { 'markdown' },
    keys = {
      { '<leader>md', ':RenderMarkdown toggle<CR>' },
    },
    config = function(_, opts)
      require('render-markdown').setup(opts)
      -- Decoration chunks (list markers, heading icons) must inherit the
      -- background they sit on, incl. the `Folded` surface of closed folds;
      patch_render_markdown_hl_fold()
    end,
  },
}
