-- Declare a global function to retrieve the current directory
function _G.get_oil_winbar()
  local bufnr = vim.api.nvim_win_get_buf(vim.g.statusline_winid)
  local dir = require('oil').get_current_dir(bufnr)
  if dir then
    return vim.fn.fnamemodify(dir, ':~')
  else
    -- If there is no current directory (e.g. over ssh), just show the buffer name
    return vim.api.nvim_buf_get_name(0)
  end
end

local function open_in_snacks_explorer()
  local dir = require('oil').get_current_dir(0)
  if dir then
    Snacks.explorer({ cwd = dir })
  end
end

return {
  'stevearc/oil.nvim',
  config = function()
    ---@module 'oil'
    ---@type oil.SetupOpts
    require('oil').setup({
      keymaps = {
        ['<C-h>'] = false,
        ['<C-l>'] = false,
        ['<C-p>'] = false,
        ['<C-s>'] = false,
        ['gp'] = 'actions.preview',
        ['ge'] = open_in_snacks_explorer,
      },

      win_options = {
        winbar = '%!v:lua.get_oil_winbar()',
      },
    })
    vim.keymap.set('n', state.keys['<C-S-E>'], ':Oil<cr>', { desc = 'oil: Open parent directory' })
    vim.keymap.set('n', '-', ':Oil<cr>', { desc = 'oil: Open parent directory' })
    vim.keymap.set('n', '_', ':Oil .<cr>', { desc = 'oil: Open parent directory' })
  end,
  dependencies = { { 'nvim-mini/mini.icons', opts = {} } },
  lazy = false, -- Lazy loading is not recommended because it is very tricky to make it work correctly in all situations.
}
