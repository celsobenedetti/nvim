return {
  {
    'zbirenbaum/copilot.lua',
    lazy = not C.opt.copilot,
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
