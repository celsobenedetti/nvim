return {
  {
    'zbirenbaum/copilot.lua',
    enabled = C.global.copilot,
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
