return {
  'mbbill/undotree',
  lazy = false,
  keys = { { '<leader>U', '<cmd>UndotreeToggle<cr>', desc = 'Undotree Toggle' } },
  config = function()
    vim.opt.undodir = os.getenv 'HOME' .. '/.vim/undodir'
  end,
}
