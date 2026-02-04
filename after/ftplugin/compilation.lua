_G.open_file_in_top_split = _G.open_file_in_top_split
  or function()
    local file = vim.fn.expand('<cfile>')
    if file == '' then
      return nil
    end
    vim.cmd('wincmd k')
    vim.cmd('edit ' .. vim.fn.fnameescape(file))
  end

vim.api.nvim_buf_set_keymap(0, 'n', 'gf', ':lua _G.open_file_in_top_split()<CR>', {
  desc = 'compilation: open file in top split',
})
