local window = require("lib.window")

local M = {}

local state = {
  win = nil, --- @type number | nil
  buf = nil, --- @type number | nil
}

--  togglable terminal on the bottom of the screeen
-- -- requirements:
-- --     1. preserve state: shell and running commands.
-- --     2. must behave like any neovim buffer
-- --        can move cursor in normal mode, yank text, search with flash.nvim
-- --        can send to new tab, split, vsplit, etc
-- --     3. when sending terminal to new tab, reset state
--            if toggled again, fresh terminal is opened
-- --
-- -- references:
-- --   https://www.youtube.com/watch?v=ooTcnx066Do
-- --   ~/local/advent-of-nvim-tj/nvim/plugin/floaterminal.lua
M.toggle_term = function()
  local ok, current_buf = pcall(vim.api.nvim_win_get_buf, state.win)
  if not ok then
    state.win = window.below(state.buf)
    if not state.buf then
      vim.api.nvim_command("terminal")
    end

    return
  end

  state.buf = current_buf
  vim.api.nvim_win_hide(state.win)
  state.window = nil
end

-- this augruop serves as a "tabpage" event handler for friendly term
-- when we send the friendly term to a new tab, reset the state
-- this disowns terminal, leaving it as a regular buffer
vim.api.nvim_create_autocmd("TabNewEntered", {
  callback = function()
    if vim.api.nvim_get_current_buf() == state.buf then
      state.buf = nil
    end
  end,
})

return M
