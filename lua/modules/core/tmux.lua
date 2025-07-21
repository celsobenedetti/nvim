--- Runs cmd if not inside Luasnip snippet
---@param cmd string
local cmd = function(cmd)
  return function()
    if not require("luasnip").in_snippet() then
      vim.cmd(cmd)
    end
  end
end
return {
  {
    "christoomey/vim-tmux-navigator",
    keys = {
      { "<C-h>", cmd("TmuxNavigateLeft"), desc = "Go to Left tmux pane" },
      { "<C-j>", cmd("TmuxNavigateDown"), desc = "Go to Down tmux pane" },
      -- { '<C-k>', cmd 'TmuxNavigateUp', desc = 'Go to Up tmux pane' },
      { "<C-l>", cmd("TmuxNavigateRight"), desc = "Go to Right tmux pane" },
    },
  },
}
