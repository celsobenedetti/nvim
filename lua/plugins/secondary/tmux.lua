if not lib.tmux.active() then
  -- keymaps that only should be available outside tmux
  -- TODO: have a tmux version of this using "set in allacritty"
  vim.keymap.set('n', '<C-S-d>', ':DapViewToggle<CR>', { desc = 'Overseer toggle' })

  -- workspace keymap: available outside tmux too
  vim.keymap.set({ 'n', 'i', 't' }, '<A-f>', function()
    vim.cmd('silent! !tmux neww -n workspace ~/scripts/workspace.sh')
  end, { desc = 'workspace: open' })

  -- return plugin so it is not cleaned up by lazy
  return { 'christoomey/vim-tmux-navigator', lazy = true }
end

--- Runs cmd if not inside snippet
---@param cmd string
local cmd = function(cmd)
  -- NOTE: feed the <esc>s when the key is pressed, never while building the
  -- lazy spec below: cmd(...) is called at spec-parse time there, and stray
  -- escapes at startup cancel a pending insert mode (e.g. org-capture
  -- autoinsert, gitcommit's startinsert).
  return function()
    -- escape
    vim.api.nvim_feedkeys(lib.keys.termcodes('<esc>'), 'n', true)
    vim.api.nvim_feedkeys(lib.keys.termcodes('<esc>'), 'n', true)

    local ok, luasnip = pcall(require, 'luasnip')
    if not ok or not luasnip.in_snippet() then
      vim.cmd(cmd)
    end
  end
end

-- disable default mappings
vim.cmd('let g:tmux_navigator_no_mappings = 1')

-- TODO: refactor: create "tmux_keymap" util function to set keymap if/if not tmux
--- workspace keymap: open new tmux window running workspace.sh
--- works in/out of tmux
local function workspace()
  if not lib.tmux.active() then
    vim.cmd('silent! !tmux neww -n workspace ~/scripts/workspace.sh')
  else
    vim.cmd('silent! !~/scripts/workspace.sh &')
  end
end

return {
  {
    'christoomey/vim-tmux-navigator',
    event = 'VeryLazy',
    keys = {
      {
        '<A-f>',
        workspace,
        desc = 'workspace: open',
        mode = { 'n', 'i', 't' },
      },
      {
        '<C-h>',
        function()
          if lib.zen.get() then
            vim.cmd('!tmux select-pane -t 0')
            return
          end
          return cmd('TmuxNavigateLeft')()
        end,
        desc = 'Go to Left tmux pane',
        mode = { 'n', 'i', 't' },
      },
      { '<C-j>', cmd('TmuxNavigateDown'), desc = 'Go to Down tmux pane', mode = { 'n', 'i' } },
      { '<C-l>', cmd('TmuxNavigateRight'), desc = 'Go to Right tmux pane', mode = { 'n', 't' } },
      { '<C-k>', cmd('TmuxNavigateUp'), desc = 'Go to Up tmux pane', mode = { 'n', 'i', 't' } },

      {
        '<C-k>',
        function()
          local selection = lib.visual.get_selection()

          vim.api.nvim_feedkeys(lib.keys.termcodes('<Esc>'), 'n', true)
          if not selection or selection == '' then
            return
          end

          local escaped = selection:gsub("'", "'\\''")
          lib.tmux.send_text(escaped)
        end,
        desc = 'Send visual selection to right tmux pane',
        mode = 'v',
      },

      -- {
      --   '<c-_>',
      --   '<cmd>OverseerRun<cr>',
      --   desc = 'overseer: run',
      --   mode = { 'n', 't' },
      -- },

      -- keymaps needed only when inside tmux tmux only
      -- { '<C-e>', Explorer, desc = 'Snacks: explorer' },
      -- NOTE: disable snacks terminal for now
      -- {
      --   '<c-_>',
      --   function()
      --     Snacks.terminal.toggle()
      --   end,
      --   desc = 'snacks: toggle terminal',
      --   mode = { 'n', 't' },
      -- },
    },
  },
}
