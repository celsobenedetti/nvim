return {
  {
    'https://codeberg.org/evergarden/nvim',
    name = 'evergarden',
    lazy = true,
    config = function(_, opts)
      local should_override = true
      local lib_colors = require('lib.colors')
      local colorscheme = lib_colors.omarchy_colorscheme()
      if colorscheme.colorscheme ~= 'evergarden' and colorscheme.colorscheme ~= 'evergarden-summer' then
        return {}
      end
      local light = colorscheme.colorscheme_plugin.opts.theme.variant == 'summer'

      local colors = vim.g.colors
      colors.white = '#F8F9E8'
      colors.red = colors.color1
      colors.yellow = colors.color3
      colors.gray = colors.color8
      colors.lime = colors.color2
      colors.orange = '#F7A182'
      colors.skye = colors.color0
      colors.secondary = colors.color7
      vim.g.colors = colors

      local config = {
        highlights = {
          keyword = { fg = vim.g.colors.red, style = { 'nocombine' } },
          type = { vim.g.colors.yellow, style = { 'nocombine' } },
          comment = { fg = vim.g.colors.gray, style = { 'italic' } },
        },
      }

      local global_overrides = {
        ['@keyword'] = config.highlights.keyword,
        ['@constant'] = { fg = vim.g.colors.white },
        ['@annotation'] = { vim.g.colors.white, style = { 'bold' } },
        ['Title'] = { link = 'Special' },
      }

      local overrides_dark = vim.tbl_extend('force', global_overrides, {
        ['@attribute'] = { vim.g.colors.orange },
        ['@markup.italic'] = { vim.g.colors.lime, style = { 'italic' } },
        ['@markup.link.label.markdown_inline'] = { vim.g.colors.skye, style = { 'bold' } },

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
