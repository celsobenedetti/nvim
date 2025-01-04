return {
  {
    'zbirenbaum/copilot.lua',
    enabled = vim.g.copilot,
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
