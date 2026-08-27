-- Integration test (real nvim, headless): :Bprev / :Bnext navigate buffers by
-- access order (MRU) rather than buffer number.
--
-- Run via `make test-integration` (nvim --headless -u NONE -l).

local cwd = vim.fn.getcwd()
vim.opt.rtp:prepend(cwd)
vim.opt.rtp:append(cwd .. '/after')
package.path = cwd .. '/lua/?.lua;' .. package.path

-- Wire up the `lib` global the way lua/init/globals.lua does in the real config.
vim.cmd('luafile ' .. cwd .. '/lua/init/globals.lua')
vim.cmd('luafile ' .. cwd .. '/after/plugin/browser-history.lua')

local function assert_eq(got, want, msg)
  if vim.inspect(got) ~= vim.inspect(want) then
    error(string.format('%s: got %s, want %s', msg or 'assert', vim.inspect(got), vim.inspect(want)))
  end
end

require('lib.browser_history').reset()

-- Create three buffers and navigate through them with real switches so the
-- BufEnter autocmd records the access order: 1 -> 2 -> 3 -> 2.
local b1 = vim.fn.bufadd('/tmp/bh-1.txt')
local b2 = vim.fn.bufadd('/tmp/bh-2.txt')
local b3 = vim.fn.bufadd('/tmp/bh-3.txt')

vim.api.nvim_set_current_buf(b1)
vim.api.nvim_set_current_buf(b2)
vim.api.nvim_set_current_buf(b3)
vim.api.nvim_set_current_buf(b2) -- from 3 to 2; 2 is now most recent

vim.cmd('Bprev')
assert_eq(vim.api.nvim_get_current_buf(), b3, 'Bprev jumps to the most recently left buffer (3)')

vim.cmd('Bnext')
assert_eq(vim.api.nvim_get_current_buf(), b2, 'Bnext returns to the buffer left before Bprev (2)')

-- A fresh navigation clears the forward history: Bnext has nowhere to go.
vim.cmd('Bprev')
vim.api.nvim_set_current_buf(b1) -- new visit, clears forward
vim.cmd('Bnext')
assert_eq(vim.api.nvim_get_current_buf(), b1, 'Bnext is a no-op after a fresh navigation')

-- Empty back stack: Bprev stays put.
require('lib.browser_history').reset()
vim.cmd('Bprev')
assert_eq(vim.api.nvim_get_current_buf(), b1, 'Bprev with empty back stack stays on current buffer')

print('OK')
