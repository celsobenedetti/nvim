vim.g.lazy_orgmode = false
vim.g.lsp = false
require('init')

require('lazy').setup({
  spec = {
    { import = 'modules.base' },
    { import = 'modules.orgmode' },
    { import = 'modules.omarchy' },
    { 'folke/snacks.nvim', opts = { picker = {} } },
    -- BUG: nvim orgmode C-c
    {
      'b0o/incline.nvim',
      dependencies = { { 'nvim-mini/mini.icons', config = true } },
      config = require('config.plugin.incline').config,
    },
  },
  performance = vim.g.lazy_nvim_config.performance,
})

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
      vim.keymap.set('n', '<C-c>', '<cmd>wqa<cr>', { buffer = true, noremap = true, silent = true, nowait = true })
    end)
  end,
})

Org.capture.c()

vim.keymap.set('n', 'R', function()
  local orgmode = require('orgmode')
  if orgmode.capture then
    orgmode.capture:refile_to_destination():next(function()
      vim.cmd.write()
      vim.cmd.quit()
    end)
  end
end)

vim.opt.number = false
vim.opt.laststatus = 0

vim.api.nvim_set_hl(0, 'Title', { link = 'Special' })

vim.opt.shortmess:append({
  I = true, -- disable intro screen
})
