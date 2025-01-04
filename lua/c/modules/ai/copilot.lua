return {
  {
    'zbirenbaum/copilot.lua',
    enabled = Globals.copilot,
    event = 'VeryLazy',
    opts = {
      filetypes = {
        yaml = true,
        json = true,
      },
      suggestion = { enabled = false },
      panel = { enabled = false },
    },
  },
}
