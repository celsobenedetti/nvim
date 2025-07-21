C = {
  colors = require("config.colors"),

  notes = require("config.zk"), -- NOTES config
}

Keys = function(str)
  return vim.api.nvim_replace_termcodes(str, false, false, true)
end

map = vim.keymap.set
