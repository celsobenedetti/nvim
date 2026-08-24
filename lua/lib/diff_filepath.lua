--- @class LibDiffFilepath
--- Render each `diff --git` header line in fugitive patch buffers as a
--- winbar-like filepath bar: filetype icon + path + `+N -M` summary, overlaid
--- via extmarks. The buffer text is never touched.
---
--- The namespace is named `nvim.*` deliberately: nvim-treesitter-context's
--- render.copy_extmarks only mirrors extmarks from namespaces whose name starts
--- with `nvim.` into its floating context window, so the same bar shows up in
--- the sticky context line above the buffer for free.
local M = {}

local Diff = require('lib.Diff')
local ns = vim.api.nvim_create_namespace('nvim.diff_filepath')

--- Build the `[text, hl]` virt_text chunks for one block header. When
--- `hovered`, use the Hover palette variants (same text, see M.set_hover);
--- the icon stacks the base range group beneath it for a shared background.
---@param block table from lib.Diff.parse_blocks
---@param hovered boolean
---@return table[] chunks
local function chunks_for(block, hovered)
  local base = hovered and 'DiffFileBarHover' or 'DiffFileBar'
  local chunks = {}
  if block.icon ~= '' then
    local hl = block.icon_hl and { base, block.icon_hl } or base .. 'Path'
    chunks[#chunks + 1] = { block.icon .. ' ', hl }
  end
  chunks[#chunks + 1] = { block.path, base .. 'Path' }
  if block.summary ~= '' then
    -- summary_text() already leads with a space (` +5 -2`).
    chunks[#chunks + 1] = { block.summary, base .. 'Summary' }
  end
  return chunks
end

--- DiffTree-hovered block header row per buffer: `bufnr -> row | nil`. Set by
--- M.set_hover, read by M.render so streaming replans keep the hover styling.
local hover_rows = {}

--- Clear and re-set the header bars for a buffer.
---@param bufnr integer
M.render = function(bufnr)
  -- Normalized: hover state is keyed by real buffer number too.
  bufnr = bufnr == 0 and vim.api.nvim_get_current_buf() or bufnr
  if not vim.api.nvim_buf_is_valid(bufnr) or vim.bo[bufnr].filetype ~= 'git' then
    hover_rows[bufnr] = nil
    return
  end

  vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
  for b in pairs(hover_rows) do
    if not vim.api.nvim_buf_is_valid(b) then
      hover_rows[b] = nil
    end
  end

  local ok, blocks = pcall(Diff.parse_blocks, bufnr)
  if not ok then
    return
  end

  for _, block in ipairs(blocks) do
    if block.path ~= '' then
      local hovered = block.row == hover_rows[bufnr]
      vim.api.nvim_buf_set_extmark(bufnr, ns, block.row, 0, {
        -- Whole-line range; fg matches bg so the raw header text is invisible
        -- beneath the overlay. end_row (rather than end_col=-1) keeps the mark
        -- copy-shaped for treesitter-context. Hovered blocks swap in the Hover
        -- palette for both the range fill and the overlay chunks.
        end_row = block.row + 1,
        hl_group = hovered and 'DiffFileBarHover' or 'DiffFileBar',
        hl_eol = true,
        virt_text = chunks_for(block, hovered),
        virt_text_pos = 'overlay',
        -- Default priority (4096) already draws above treesitter's 100.
      })
    end
  end
end

--- Mark `row` (a `diff --git` header row, 0-based) as the DiffTree-hovered
--- file and re-render its bar on the Hover palette; nil clears. Called from
--- lib.Diff's tree focus_row: hovering a tree file row must light up the bar
--- itself, and no second extmark can restyle this namespace's baked-in
--- virt_text highlights — so the hovered block's mark is re-emitted with
--- Hover-group chunks instead of layering a highlight over the raw (already
--- invisible) text. render() honors the stored row too, so streaming replans
--- keep the styling.
---@param bufnr integer
---@param row? integer
M.set_hover = function(bufnr, row)
  bufnr = bufnr == 0 and vim.api.nvim_get_current_buf() or bufnr
  if not vim.api.nvim_buf_is_valid(bufnr) or hover_rows[bufnr] == row then
    return
  end
  hover_rows[bufnr] = row
  M.render(bufnr)
end

--- Currently hovered block header row for a buffer, or nil.
---@param bufnr integer
---@return integer?
M.hover = function(bufnr)
  return hover_rows[bufnr == 0 and vim.api.nvim_get_current_buf() or bufnr]
end

return M
