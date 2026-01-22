local should_override = true
local c = require('config.colors').evergarden -- colors
local colorscheme = require('lib.colors').omarchy_colorscheme()
if colorscheme.colorscheme ~= 'evergarden' then
  return {}
end
local light = colorscheme.colorscheme_plugin.opts.theme.variant == 'summer'

local config = {
  highlights = {
    keyword = { fg = c.red, style = { 'nocombine' } },
    type = { c.yellow, style = { 'nocombine' } },
    comment = { fg = c.gray, style = { 'italic' } },
  },
}

local overrides_dark = {
  ['@keyword'] = config.highlights.keyword,
  ['@constant'] = { c.white },
  ['@annotation'] = { c.white, style = { 'bold' } },
  ['@attribute'] = { c.orange },
  ['@markup.italic'] = { c.lime, style = { 'italic' } },
  ['@markup.link.label.markdown_inline'] = { c.skye, style = { 'bold' } },

  -- ['typescriptVariable'] = { c.orange },
  -- SpellBad = { style = { 'italic', 'underdotted' } },
  -- TabLineSel = { bg = c.inactivegray },
}

local overrides_light = {
  ['WinSeparator'] = { fg = c.summer.text },
}

local overrides = light and overrides_light or overrides_dark

if not should_override then
  overrides = {}
end

return {
  {
    'everviolet/nvim',
    name = 'evergarden',
    lazy = true,
    opts = {
      overrides = overrides,
      integrations = {
        cmp = true,
        gitsigns = true,
        lualine = true,
        mini = {
          enable = true,
          animate = true,
          clue = true,
          completion = true,
          cursorword = true,
          deps = true,
          diff = false,
          files = true,
          hipatterns = true,
          icons = true,
          indentscope = true,
          jump = true,
          jump2d = true,
          map = true,
          notify = true,
          operators = true,
          pick = true,
          starters = true,
          statusline = true,
          surround = true,
          tabline = true,
          test = true,
          trailspace = true,
        },
        telescope = false,
        which_key = true,
      },
    },
  },
}
