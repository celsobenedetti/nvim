map = vim.keymap.set

ToggleTerm = require("lib.toggle_term")

Keys = function(str)
  return vim.api.nvim_replace_termcodes(str, false, false, true)
end
