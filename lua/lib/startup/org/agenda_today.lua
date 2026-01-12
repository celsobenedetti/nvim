local fullscreen = true

-- vim.defer_fn(function()
require('lib.notes').focus_or_create_notes_tab(function()
  vim.cmd(':Org agenda T')
  vim.schedule(function()
    vim.cmd('tabclose 1')

    if fullscreen then
      vim.defer_fn(function()
        vim.cmd('wincmd k')
        vim.api.nvim_win_close(0, false)
      end, 50)
    end
  end)
end)
-- end, 10)
