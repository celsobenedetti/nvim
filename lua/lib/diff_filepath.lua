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

--- Build the `[text, hl]` virt_text chunks for one block header.
---@param block table from lib.Diff.parse_blocks
---@return table[] chunks
local function chunks_for(block)
  local chunks = {}
  if block.icon ~= '' then
    chunks[#chunks + 1] = { block.icon .. ' ', block.icon_hl or 'DiffFileBarPath' }
  end
  chunks[#chunks + 1] = { block.path, 'DiffFileBarPath' }
  if block.summary ~= '' then
    -- summary_text() already leads with a space (` +5 -2`).
    chunks[#chunks + 1] = { block.summary, 'DiffFileBarSummary' }
  end
  return chunks
end

--- Clear and re-set the header bars for a buffer.
---@param bufnr integer
M.render = function(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) or vim.bo[bufnr].filetype ~= 'git' then
    return
  end

  vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)

  local ok, blocks = pcall(Diff.parse_blocks, bufnr)
  if not ok then
    return
  end

  for _, block in ipairs(blocks) do
    if block.path ~= '' then
      vim.api.nvim_buf_set_extmark(bufnr, ns, block.row, 0, {
        -- Whole-line range; fg matches bg so the raw header text is invisible
        -- beneath the overlay. end_row (rather than end_col=-1) keeps the mark
        -- copy-shaped for treesitter-context.
        end_row = block.row + 1,
        hl_group = 'DiffFileBar',
        hl_eol = true,
        virt_text = chunks_for(block),
        virt_text_pos = 'overlay',
        -- Default priority (4096) already draws above treesitter's 100.
      })
    end
  end
end

return M
