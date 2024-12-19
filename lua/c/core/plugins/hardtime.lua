return {
  -- lazy.nvim
  {
    'm4xshen/hardtime.nvim',
    enabled = false,
    dependencies = { 'MunifTanjim/nui.nvim', 'nvim-lua/plenary.nvim' },
    opts = {
      max_count = 10,
    },
  },
}
