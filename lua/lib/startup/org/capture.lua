require('orgmode')

local DELAY_CLOSE_WIN = 150

vim.schedule(function()
  vim.cmd('Org capture c')

  vim.defer_fn(function()
    vim.cmd('wincmd k')
    vim.api.nvim_win_close(0, false)
  end, DELAY_CLOSE_WIN)
end)
