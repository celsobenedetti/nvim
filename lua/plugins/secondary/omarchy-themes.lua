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

  -- add plugin from omarchy current theme and set colorscheme
  vim.tbl_extend('keep', state.omarchy_colorscheme.colorscheme_plugin, {
    init = function()
      vim.cmd('colorscheme ' .. state.omarchy_colorscheme.colorscheme)
    end,
  }),
}
