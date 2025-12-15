return {
  'bassamsdata/namu.nvim',
  cmd = 'Namu',

  init = function()
    vim.keymap.set('n', '♠', ':Namu symbols<cr>', {
      desc = 'Jump to LSP symbol',
      silent = true,
    })
    vim.keymap.set('n', '<leader>sw', ':Namu workspace<cr>', {
      desc = 'LSP Symbols - Workspace',
      silent = true,
    })
  end,
  opts = {
    global = {
      window = {
        auto_size = true,
        min_width = 70,
      },
      display = {
        format = 'tree_guides',
      },
      -- },
      namu_symbols = { -- Specific Module options
      },
    },
  },
  -- === Suggested Keymaps: ===
}
