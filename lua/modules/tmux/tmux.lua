local tmux = os.getenv('TMUX')
if not tmux or tmux == '' then
  -- keymaps that only should be available outside tmux
  map('n', '<C-S-P>', function()
    Snacks.picker.keymaps()
  end, { desc = 'Overseer toggle' })
  return { 'christoomey/vim-tmux-navigator', lazy = true }
end

--- Runs cmd if not inside snippet
---@param cmd string
local cmd = function(cmd)
  -- escape
  vim.api.nvim_feedkeys(Keys('<esc>'), 'n', true)
  vim.api.nvim_feedkeys(Keys('<esc>'), 'n', true)

  return function()
    local ok, luasnip = pcall(require, 'luasnip')
    if not ok or not luasnip.in_snippet() then
      vim.cmd(cmd)
    end
  end
end

-- disable default mappings
vim.cmd('let g:tmux_navigator_no_mappings = 1')

return {
  {
    'christoomey/vim-tmux-navigator',
    event = 'VeryLazy',
    keys = {
      {
        '<C-h>',
        function()
          if Snacks.zen.win and not Snacks.zen.win.closed then
            vim.cmd('!tmux select-pane -t 0')
            return
          end
          return cmd('TmuxNavigateLeft')()
        end,
        desc = 'Go to Left tmux pane',
      },
      { '<C-j>', cmd('TmuxNavigateDown'), desc = 'Go to Down tmux pane' },
      { '<C-k>', cmd('TmuxNavigateUp'), desc = 'Go to Up tmux pane' },
      { '<C-l>', cmd('TmuxNavigateRight'), desc = 'Go to Right tmux pane' },

      -- keymaps needed only when inside tmux tmux only
      { '<C-e>', Explorer, desc = 'Snacks: explorer' },
      {
        '<c-_>',
        function()
          Snacks.terminal(nil, { cwd = require('lib.cwd').root() })
        end,
        desc = 'Terminal (Root Dir)',
        mode = { 'n', 't' },
      },
    },
  },
}
