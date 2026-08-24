-- Integration test (real nvim, headless): lib.fold_hl stamps one bg-only
-- `line_hl_group` extmark at near-max priority on each closed fold's first
-- line, so a folded line has a single background whatever else painted it.
--
-- Run via `make test-integration` (nvim --headless -u NONE -l).

vim.opt.rtp:prepend(vim.fn.getcwd())
package.path = vim.fn.getcwd() .. '/lua/?.lua;' .. package.path

local function assert_eq(got, want, msg)
  if vim.inspect(got) ~= vim.inspect(want) then
    error(string.format('%s: got %s, want %s', msg or 'assert', vim.inspect(got), vim.inspect(want)))
  end
end

local fold_hl = require('lib.fold_hl')

vim.api.nvim_set_hl(0, 'Folded', { bg = '#111111' })

local win = vim.api.nvim_get_current_win()
local buf = vim.api.nvim_get_current_buf()
local lines = {}
for i = 1, 24 do
  lines[i] = 'line ' .. i
end
vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

vim.wo[win].foldmethod = 'manual'
vim.cmd('5,9fold')
vim.cmd('15,19fold')
vim.cmd('normal! zR')

--- The namespace fold_hl created for this window (never `nvim.*`: see the
--- module comment).
local function fold_ns()
  for name, id in pairs(vim.api.nvim_get_namespaces()) do
    if name:match('^fold_hl%.') then
      return id
    end
  end
end

local function marks()
  local out = {}
  for _, m in ipairs(vim.api.nvim_buf_get_extmarks(buf, fold_ns() or -1, 0, -1, { details = true })) do
    out[#out + 1] = { row = m[2], group = m[4].line_hl_group, priority = m[4].priority }
  end
  return out
end

-- Nothing folded: nothing stamped.
fold_hl.refresh(win)
assert_eq(marks(), {}, 'open folds leave the buffer alone')

vim.cmd('5normal! zc')
vim.cmd('15normal! zc')
fold_hl.refresh(win)
assert_eq(marks(), {
  { row = 4, group = 'FoldFlatFolded', priority = 65534 },
  { row = 14, group = 'FoldFlatFolded', priority = 65534 },
}, 'each closed fold gets one bg-only stamp on its first line')

-- The derived group copies the background and nothing else, so foregrounds on
-- the fold line survive.
assert_eq(
  vim.api.nvim_get_hl(0, { name = 'FoldFlatFolded' }),
  { bg = tonumber('111111', 16) },
  'stamp group is bg-only'
)

-- The fold under the cursor keeps its 'cursorline' background.
vim.wo[win].cursorline = true
vim.api.nvim_win_set_cursor(win, { 5, 0 })
fold_hl.refresh(win)
assert_eq(
  marks(),
  { { row = 14, group = 'FoldFlatFolded', priority = 65534 } },
  "cursor's fold is skipped while 'cursorline' is on"
)

vim.wo[win].cursorline = false
fold_hl.refresh(win)
assert_eq(#marks(), 2, "without 'cursorline' every fold is stamped")

-- 'winhighlight' picks the fold surface per window, which is how a filetype
-- opts into its own color (`Folded:DiffFolded` in after/ftplugin/git.lua).
vim.api.nvim_set_hl(0, 'MyFold', { bg = '#222222' })
vim.wo[win].winhighlight = 'Normal:Normal,Folded:MyFold'
fold_hl.refresh(win)
assert_eq(marks()[1].group, 'FoldFlatMyFold', "'winhighlight' remap of Folded chooses the source group")
assert_eq(
  vim.api.nvim_get_hl(0, { name = 'FoldFlatMyFold' }),
  { bg = tonumber('222222', 16) },
  'derived from the remapped group'
)

-- A source group with no background has nothing to consolidate.
vim.api.nvim_set_hl(0, 'NoBgFold', { fg = '#333333' })
vim.wo[win].winhighlight = 'Folded:NoBgFold'
fold_hl.refresh(win)
assert_eq(marks(), {}, 'a fold surface without a background stamps nothing')

vim.wo[win].winhighlight = ''
vim.b[buf].fold_hl_disable = true
fold_hl.refresh(win)
assert_eq(marks(), {}, 'vim.b.fold_hl_disable opts a buffer out')
vim.b[buf].fold_hl_disable = nil

-- Opening a fold drops its stamp.
vim.cmd('normal! zR')
fold_hl.refresh(win)
assert_eq(marks(), {}, 'reopening the folds clears every stamp')

print('OK: lib.fold_hl consolidated fold backgrounds')
vim.cmd('qa!')
