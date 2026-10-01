state.lsp = false
state.capture = true

local initial_window = vim.api.nvim_get_current_win()
vim.api.nvim_create_autocmd('FileType', {
  desc = 'close initial window when capture buffer shows',
  pattern = 'org',
  callback = function()
    -- Delete any existing "Untitled" buffers
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      local name = vim.api.nvim_buf_get_name(buf)
      if name:match('Untitled') and buf ~= vim.api.nvim_get_current_buf() then
        pcall(vim.api.nvim_buf_delete, buf, { force = true })
      end
    end
    pcall(vim.api.nvim_win_close, initial_window, true)
    vim.b.capture_buffer = vim.api.nvim_get_current_buf()
    -- Override orgmode's C-c mapping with wqa behavior (defer to ensure it runs after orgmode setup)
    vim.schedule(function()
      vim.keymap.set('n', '<C-c>', function()
        vim.cmd('w!')
        vim.cmd('q!')
      end, { buffer = true, noremap = true, silent = true, nowait = true })
    end)
  end,
})

vim.cmd('Org capture c')

vim.api.nvim_set_hl(0, 'Title', { link = 'Special' })

vim.opt.shortmess:append({
  I = true, -- disable intro screen
})
