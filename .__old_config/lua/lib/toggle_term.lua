local window = require 'lib.window'

---@deprecated
-- NOTE: 2025-08-07 I'm ditching this toggle term approach.
-- it is pretty interesting, but not perfect either.
-- I'm setling for LazyVim toggleterm for friendly term, and overseer.nvim for other processes.
local M = {
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
--
-- NOTE : 2025-07-27 I decided to go for a "relative" (float) window for the terminal on the bottom
-- this is because we can use (style = "minimal", border = "single") which look great.
-- however this causes issues, since floating window navigation is treaky.
-- to work around this, I added a "focus" handler for <C-j> in ./lua/modules/core/tmux.lua
--
--    references:
--      https://www.youtube.com/watch?v=ooTcnx066Do
--      ~/local/advent-of-nvim-tj/nvim/plugin/floaterminal.lua
M.toggle = function()
  local ok, current_buf = pcall(vim.api.nvim_win_get_buf, M.win)

  if not ok then
    if vim.g.toggle_term_relative then
      M.win = window.relative_below(M.buf)
    else
      M.win = window.below(M.buf)
    end

    if not M.buf then
      vim.api.nvim_command 'terminal'
    end

    return
  end

  M.buf = current_buf
  vim.api.nvim_win_hide(M.win)
  M.window = nil
end

M.focus = function()
  if M.win then
    local ok, _ = pcall(vim.api.nvim_set_current_win, M.win)
    return ok
  end
  return M.win
end

-- this augruop serves as a "tabpage" event handler for friendly term
-- when we send the friendly term to a new tab, reset the state
-- this disowns terminal, leaving it as a regular buffer
vim.api.nvim_create_autocmd('TabNewEntered', {
  callback = function()
    if vim.api.nvim_get_current_buf() == M.buf then
      M.buf = nil
      M.win = nil
    end
  end,
})

return M
