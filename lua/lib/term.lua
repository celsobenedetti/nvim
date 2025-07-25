local M = {}

-- create_3_terms will spawn 3 :term buffers in a single window
-- we want 1 vertical split first-
-- the terminal on the left will have half of the screen
-- the other 2 terminals will split the remaining half horizontally
M.create_3_terms = function()
  -- Start by going to a new tab
  vim.cmd("tabnew")
  -- Vertical split: focus on right window
  vim.cmd("vsplit")
  -- Move to right window, then horizontal split: focus on bottom right window
  vim.cmd("wincmd l")
  vim.cmd("split")
  -- Open terminal in top right
  vim.cmd("wincmd k")
  vim.cmd("terminal")
  -- Open terminal in bottom right
  vim.cmd("wincmd j")
  vim.cmd("terminal")
  -- Move to left window, open terminal
  vim.cmd("wincmd h")
  vim.cmd("terminal")
  -- Optional: move back to starting window (if desired)
end

local state = {
  buf = false,
}

-- friendly terminal on the bottom

-- requirements:
--     1. quick toggle, preserve state
--     2. must behave like any old buffer
--     3. can send to different tab
--     4. once in different tab, reset "friendly term" state
--         if toggle again,
--
-- references:
--   https://www.youtube.com/watch?v=ooTcnx066Do
--   ~/local/advent-of-nvim-tj/nvim/plugin/floaterminal.lua
M.toggle_term = function()
  local job_id = 0
  job_id = vim.bo.channel
  vim.cmd.vnew()
  vim.cmd.term()
  vim.cmd.wincmd("J")
  vim.api.nvim_win_set_height(0, 5)
end

return M
