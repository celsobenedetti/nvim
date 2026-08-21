if 'evergarden' ~= state.omarchy_colorscheme.colorscheme then
  return {}
end

return {
  {
    'https://codeberg.org/evergarden/nvim',
    name = 'evergarden',
    lazy = true,
    config = function(_, opts)
      local should_override = true
      if
        state.omarchy_colorscheme.colorscheme ~= 'evergarden'
        and state.omarchy_colorscheme.colorscheme ~= 'evergarden-summer'
      then
        return {}
      end
      local light = state.omarchy_colorscheme.colorscheme_plugin.opts.theme.variant == 'summer'

      local folded = '#1C2225'
      if light then
        folded = '#e6e1d3'
      end

      lib.colors.update({
        white = '#F8F9E8',
        red = colors.color1,
        yellow = colors.color3,
        gray = colors.color8,
        lime = colors.color2,
        orange = '#F7A182',
        skye = colors.color0,
        secondary = colors.color7,
        mantle = '#1c2225',
        blue = '#B2CAED',
        purple = '#D2BDF3',
        green = '#CBE3B3',
        links = colors.accent,
        folded = folded,
      })

      local config = {
        highlights = {
          keyword = { fg = colors.red, style = { 'nocombine' } },
          type = { colors.yellow, style = { 'nocombine' } },
          comment = { fg = colors.gray, style = { 'italic' } },
        },
      }

      local global_overrides = {
        ['@keyword'] = config.highlights.keyword,
        ['Title'] = { link = 'Special' },
        ['@diff.add'] = { link = 'DiffAdd' },
        ['@diff.delete'] = { link = 'DiffDelete' },
      }

      local overrides_dark = vim.tbl_extend('force', global_overrides, {
        ['@annotation'] = { colors.white, style = { 'bold' } },
        ['@constant'] = { fg = colors.white },
        ['@attribute'] = { colors.orange },
        ['@markup.italic'] = { colors.lime, style = { 'italic' } },
        ['@markup.link.label.markdown_inline'] = { colors.skye, style = { 'bold' } },
        ['TreesitterContext'] = { bg = colors.mantle },

        -- ['typescriptVariable'] = { colors.orange },
        -- SpellBad = { style = { 'italic', 'underdotted' } },
        -- TabLineSel = { bg = colors.inactivegray },
      })

      local overrides_light = vim.tbl_extend('force', global_overrides, {
        -- ['WinSeparator'] = { fg = colors.summer.surface2 },
        -- ['@keyword'] = { fg = colors.summer.red, style = { 'nocombine' } },
        -- ['@constant'] = { fg = colors.summer.text },
        -- ['@annotation'] = { colors.summer.snow },
      })

      local overrides = light and overrides_light or overrides_dark

      if not should_override then
        overrides = {}
      end

      require('evergarden').setup(vim.tbl_deep_extend('force', opts, {
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
            tabline = false,
            test = true,
            trailspace = true,
          },
          telescope = false,
          which_key = true,
        },
      }))
    end,
  },
}
