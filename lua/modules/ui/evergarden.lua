local lib = {
  colors = require('lib.colors'),
}

local curr = lib.colors.omarchy_colorscheme()

if 'evergarden' ~= curr.colorscheme then
  return {}
end

return {
  {
    'https://codeberg.org/evergarden/nvim',
    name = 'evergarden',
    lazy = true,
    config = function(_, opts)
      local should_override = true
      if curr.colorscheme ~= 'evergarden' and curr.colorscheme ~= 'evergarden-summer' then
        return {}
      end
      local light = curr.colorscheme_plugin.opts.theme.variant == 'summer'

      local folded = '#1C2225'
      if light then
        folded = '#e6e1d3'
      end

      lib.colors.update({
        white = '#F8F9E8',
        red = vim.g.colors.color1,
        yellow = vim.g.colors.color3,
        gray = vim.g.colors.color8,
        lime = vim.g.colors.color2,
        orange = '#F7A182',
        skye = vim.g.colors.color0,
        secondary = vim.g.colors.color7,
        mantle = '#1c2225',
        blue = '#B2CAED',
        purple = '#D2BDF3',
        green = '#CBE3B3',
        links = vim.g.colors.accent,
        folded = folded,
      })

      local config = {
        highlights = {
          keyword = { fg = vim.g.colors.red, style = { 'nocombine' } },
          type = { vim.g.colors.yellow, style = { 'nocombine' } },
          comment = { fg = vim.g.colors.gray, style = { 'italic' } },
        },
      }

      local global_overrides = {
        ['@keyword'] = config.highlights.keyword,
        ['Title'] = { link = 'Special' },
      }

      local overrides_dark = vim.tbl_extend('force', global_overrides, {
        ['@annotation'] = { vim.g.colors.white, style = { 'bold' } },
        ['@constant'] = { fg = vim.g.colors.white },
        ['@attribute'] = { vim.g.colors.orange },
        ['@markup.italic'] = { vim.g.colors.lime, style = { 'italic' } },
        ['@markup.link.label.markdown_inline'] = { vim.g.colors.skye, style = { 'bold' } },
        ['TreesitterContext'] = { bg = vim.g.colors.mantle },

        -- ['typescriptVariable'] = { vim.g.colors.orange },
        -- SpellBad = { style = { 'italic', 'underdotted' } },
        -- TabLineSel = { bg = vim.g.colors.inactivegray },
      })

      local overrides_light = vim.tbl_extend('force', global_overrides, {
        -- ['WinSeparator'] = { fg = vim.g.colors.summer.surface2 },
        -- ['@keyword'] = { fg = vim.g.colors.summer.red, style = { 'nocombine' } },
        -- ['@constant'] = { fg = vim.g.colors.summer.text },
        -- ['@annotation'] = { vim.g.colors.summer.snow },
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
