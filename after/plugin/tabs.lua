-- Home-grown tabline: named tabs backed by lib/tab (no tabby.nvim).
local tab = require('lib.tab')

-- showtabline = 1: hide the tabline while a single tab is open (like
-- default nvim and tabby.nvim), show it once there are at least two.
vim.o.showtabline = 1
vim.o.tabline = "%!v:lua.require('lib.tab').render()"

vim.api.nvim_create_user_command('TabRename', function(opts)
  tab.rename(opts.args)
end, { nargs = '?' })

local group = vim.api.nvim_create_augroup('homegrown_tabs', { clear = true })
for _, event in ipairs({ 'TabNew', 'TabClosed', 'WinEnter', 'BufEnter', 'BufWinEnter', 'TermOpen' }) do
  vim.api.nvim_create_autocmd(event, {
    group = group,
    callback = function()
      vim.cmd('redrawtabline')
    end,
  })
end