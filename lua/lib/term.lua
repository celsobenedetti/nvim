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

return M
