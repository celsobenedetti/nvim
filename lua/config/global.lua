C = {
  colors = require("config.colors"),
}

Keys = function(str)
  return vim.api.nvim_replace_termcodes(str, false, false, true)
end

map = vim.keymap.set
