return {
  {
    'zbirenbaum/copilot.lua',
    enabled = C.Globals.copilot,
    event = 'VeryLazy',
    opts = {
      filetypes = {
        yaml = true,
        json = true,
      },
      suggestion = { enabled = false },
      panel = { enabled = false },
    },
    dependencies = {
      C.Lualine.add_cmp_source 'copilot',
    },
  },
}
