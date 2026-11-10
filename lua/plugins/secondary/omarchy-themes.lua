if
  not state.omarchy_colorscheme
  or not state.omarchy_colorscheme.colorscheme
  or not state.omarchy_colorscheme.colorscheme_plugin
then
  return {}
end

return {
  -- explicitly disable LazyVim, which is enabled by the plugin
  { 'LazyVim/LazyVim', enabled = false },

  -- these are here so that lazy.nvim does not clean then up
  { 'celsobenedetti/tufte.nvim' },
  -- { 'nordtheme/vim' },
  { 'https://github.com/gbprod/nord.nvim' },

  -- add plugin from omarchy current theme and set colorscheme
  vim.tbl_extend('keep', state.omarchy_colorscheme.colorscheme_plugin, {
    init = function()
      local colorscheme = state.omarchy_colorscheme.colorscheme
      if colorscheme:find('nordfox') then
        colorscheme = 'nord'
      end
      vim.cmd.colorscheme(colorscheme)
    end,
  }),
}
