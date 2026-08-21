-- delta-style intra-line emphasis for fugitive patch buffers.
--
-- `:Git log -p`, `:Git show`, and `:Git diff` output lands in
-- filetype=git buffers where syntax/diff.vim already washes whole +/- lines
-- (diffAdded/diffRemoved). This layers word-level emphasis on top: the
-- changed words inside those lines get PlusEmph/MinusEmph backgrounds, like
-- delta's plus-emph-style/minus-emph-style.
--
-- Fugitive types the buffer BEFORE its job streams output into it, so a
-- single pass on FileType sees an empty buffer. Watch on_lines instead and
-- re-plan (coalesced per event-loop tick) while content streams in; the
-- pass is O(buffer) which stays cheap because vim.text.diff does the heavy
-- lifting in C.

local function has_patch(lines)
  for _, line in ipairs(lines) do
    if line:sub(1, 3) == '@@ ' then
      return true
    end
  end
  return false
end

local bufnr = vim.api.nvim_get_current_buf()
if vim.b[bufnr].diff_emph_setup then
  return
end
vim.b[bufnr].diff_emph_setup = true

local ns = vim.api.nvim_create_namespace('diff_emph')
local pending = false

---@param firstline? integer limit replan from this row (nil = whole buffer)
local function replan()
  pending = false
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  if not has_patch(lines) then
    return
  end
  local ok, regions = pcall(require('lib.diff_emph').plan, lines)
  if not ok then
    vim.notify('diff_emph: ' .. tostring(regions), vim.log.levels.WARN)
    return
  end
  vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
  for _, r in ipairs(regions) do
    vim.api.nvim_buf_set_extmark(bufnr, ns, r.row, r.col, {
      end_col = r.end_,
      hl_group = r.kind == 'add' and 'PlusEmph' or 'MinusEmph',
    })
  end
end

--- Coalesce bursts of streamed lines into one replan per tick.
local function schedule_replan()
  if not pending then
    pending = true
    vim.schedule(replan)
  end
end

schedule_replan()

vim.api.nvim_buf_attach(bufnr, false, {
  on_lines = schedule_replan,
})
