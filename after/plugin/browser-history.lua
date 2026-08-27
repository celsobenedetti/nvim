-- MRU buffer navigation: :Bprev / :Bnext jump through buffers by access order
-- (most recently used) instead of buffer number. Core logic in lib.browser_history.
local bh = lib.browser_history

-- Seed the current buffer so the first navigation is from a known position.
bh.record(vim.api.nvim_get_current_buf())

-- Track every buffer switch. `record` ignores the re-entry caused by our own
-- prev/next jumps (current is updated synchronously before the switch), so
-- normal navigation lands here once and pushes the previous buffer onto back.
vim.api.nvim_create_autocmd('BufEnter', {
  group = vim.api.nvim_create_augroup('browser-history:track', { clear = true }),
  callback = function(ev)
    bh.record(ev.buf)
  end,
})

local function jump(jump_fn, dir)
  local target = jump_fn()
  if not target then
    vim.notify('No ' .. dir .. ' buffer in history', vim.log.levels.INFO)
    return
  end
  vim.api.nvim_set_current_buf(target)
end

vim.api.nvim_create_user_command('Bprev', function()
  jump(bh.prev, 'previous')
end, { desc = 'Jump to the most recently accessed buffer' })

vim.api.nvim_create_user_command('Bnext', function()
  jump(bh.next, 'next')
end, { desc = 'Jump to the buffer most recently left via Bprev' })

vim.keymap.set('n', '<M-h>', ':Bprev<CR>', { desc = 'Jump to the most recently accessed buffer' })
vim.keymap.set('n', '<M-l>', ':Bnext<CR>', { desc = 'Jump to the buffer most recently left via Bprev' })
