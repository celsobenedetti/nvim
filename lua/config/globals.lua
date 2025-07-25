map = vim.keymap.set

local colors = require("config.colors")

C = {
  colors = vim.tbl_deep_extend("keep", colors.evergarden, {
    colorscheme = colors.colorscheme,
    background = colors.background,
  }),

  notes = require("config.zk"), -- NOTES config
}

Keys = function(str)
  return vim.api.nvim_replace_termcodes(str, false, false, true)
end
