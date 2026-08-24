--- Headless integration test: the winbar renders the :Diff quickfix list's
--- breadcrumb bar (`quickfix: <icon> git > <icon> git <args>`) from
--- lib.Diff's qf-list registry, and the usual empty bar for lists lib.Diff
--- didn't create (the qf buffer is shared across lists).
---
--- Run with: nvim --headless -u NONE -l (run from the repo root; loads the
--- real after/plugin/winbar.lua and the real lib.Diff).

local repo_root = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h:h:h')
package.path = repo_root .. '/lua/?.lua;' .. package.path
vim.opt.rtp:prepend(repo_root)

-- Load the real winbar plugin with minimal globals (only `config` at load
-- time; `lib` is referenced lazily inside render functions).
_G.config = { icons = {} }
_G.lib = { strings = {
  hl = function(_, text)
    return text
  end,
} }
dofile(repo_root .. '/after/plugin/winbar.lua')
-- The quickfix branch resolves lib.Diff at render time; provide the real one.
_G.lib.Diff = require('lib.Diff')

local function assert_eq(got, want, msg)
  if got ~= want then
    error(string.format('%s: got %q, want %q', msg or 'assert', got, want))
  end
end

-- Bar as winbar.lua renders it (hl stub returns text unchanged).
local function bar_for_qf_window()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].buftype == 'quickfix' then
      vim.g.statusline_winid = win
      return _G.get_winbar()
    end
  end
  error('no quickfix window found')
end

-- :Diff-style list: register its winbar, open the qf window, expect the bar.
vim.fn.setqflist({}, ' ', {
  title = 'Diff HEAD',
  items = { { bufnr = 1, lnum = 7, text = ' 7 a.txt  +1' } },
})
local qfid = vim.fn.getqflist({ id = 0 }).id
lib.Diff.record_winbar(qfid, 'quickfix:  git >  git show HEAD')
vim.cmd('botright copen')
assert_eq(bar_for_qf_window(), 'quickfix:  git >  git show HEAD', 'Diff list renders its breadcrumb')

-- Replacing the list (e.g. :grep) creates a new id -> no registered bar.
vim.fn.setqflist({}, ' ', {
  title = 'grep foo',
  items = { { filename = '/tmp/x.txt', lnum = 1, text = 'x' } },
})
assert_eq(bar_for_qf_window(), '', 'foreign list gets the empty bar')

print('OK: Diff qf winbar breadcrumb')
vim.cmd('qa!')
