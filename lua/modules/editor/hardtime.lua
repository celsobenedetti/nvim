return {
  {
    'm4xshen/hardtime.nvim',
    lazy = not C.opt.hardtime,
    dependencies = { 'MunifTanjim/nui.nvim', 'nvim-lua/plenary.nvim' },
    opts = {
      max_count = 10,
    },
  },
}
