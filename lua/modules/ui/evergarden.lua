local should_override = true
local c = require('config.colors').evergarden -- colors

local config = {
  highlights = {
    keyword = { fg = c.red, style = { 'nocombine' } },
    type = { c.yellow, style = { 'nocombine' } },
    comment = { fg = c.gray, style = { 'italic' } },
  },
}

local overrides = {
  ['@keyword'] = config.highlights.keyword,
  ['@constant'] = { c.white },
  ['@annotation'] = { c.white },
  ['typescriptVariable'] = { c.orange },
  -- SpellBad = { style = { 'italic', 'underdotted' } },
  -- TabLineSel = { bg = c.inactivegray },
}

if not should_override then
  overrides = {}
end

return {

  {
    'everviolet/nvim',
    name = 'evergarden',
    lazy = true,
    -- priority = 1000,
    opts = {

      theme = {
        variant = 'fall', -- 'winter'|'fall'|'spring'|'summer'
        accent = 'green',
      },

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
