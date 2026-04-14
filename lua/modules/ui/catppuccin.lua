if 'catppuccin' ~= require('lib.colors').omarchy_colorscheme().colorscheme then
  return {}
end

return {
  {
    'catppuccin/nvim',
    name = 'catppuccin',
    priority = 1000,
    config = function()
      local c = vim.g.colors
      c.secondary = vim.g.colors.color7
      vim.g.colors = c
    end,
  },
}
