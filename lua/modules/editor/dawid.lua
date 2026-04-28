return {
  'rodakd/terms.nvim',
  config = function()
    require('terms').setup({
      width = 0.9, -- fraction of editor width (float/vsplit)
      height = 0.9, -- fraction of editor height (float/hsplit)
      position = 'float', -- "float" | "vsplit" | "hsplit"
      close = '<C-q>', -- buffer-local key to hide the terminal window (set to false to disable)
    })

    local terms = require('terms')

    vim.keymap.set('n', '<C-1>', function()
      terms.toggle({ cmd = 'opencode', name = 'opencode' })
    end)

    vim.keymap.set('x', '<C-1>', function()
      terms.send_selection({ cmd = 'opencode', name = 'opencode' })
    end)
    vim.keymap.set('n', '<C-2>', function()
      terms.toggle({ cmd = 'lazygit', name = 'lazygit' })
    end)

    vim.keymap.set('n', '<C-3>', function()
      terms.toggle({ cmd = 'zsh', name = 'zsh' })
    end)
  end,
}
