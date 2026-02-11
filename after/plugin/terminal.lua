-- Set local settings for terminal buffers
vim.api.nvim_create_autocmd('TermOpen', {
  group = vim.api.nvim_create_augroup('custom-term-open', {}),
  callback = function()
    vim.opt_local.number = true
    vim.opt_local.scrolloff = 0

    vim.bo.filetype = 'terminal'
  end,
})

-- allow ":wqa" with terminal open
vim.api.nvim_create_autocmd('ExitPre', {
  pattern = '*',
  callback = function(_)
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_get_option_value('buftype', { buf = buf }) == 'terminal' then
        vim.api.nvim_buf_delete(buf, { force = true })
      end
    end
  end,
})
