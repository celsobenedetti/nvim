local omarchy_colorscheme = require('lib.colors').omarchy_colorscheme()

if not omarchy_colorscheme or not omarchy_colorscheme.colorscheme or not omarchy_colorscheme.colorscheme_plugin then
  return {}
end

return {
  -- add plugin from omarchy current theme and set colorscheme
  vim.tbl_extend('keep', omarchy_colorscheme.colorscheme_plugin, {
    init = function()
      vim.cmd('colorscheme ' .. omarchy_colorscheme.colorscheme)
    end,
  }),
}
