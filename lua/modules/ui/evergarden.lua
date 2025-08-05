local rgb = require 'lib.rgb'
local c = vim.g.colors -- colors

local config = {

  -- TODO: use vim.extend_table to extend these configs

  highlights = {
    keyword = { fg = c.red, style = { 'nocombine' } },
    type = { c.yellow, style = { 'nocombine' } },
    comment = { fg = c.gray, style = { 'italic' } },
  },
}

return {

  {
    lazy = false,
    'everviolet/nvim',
    name = 'evergarden',
    priority = 1000,
    opts = {

      theme = {
        variant = 'fall', -- 'winter'|'fall'|'spring'|'summer'
        accent = 'green',
      },

      --  example for API: vim.api.nvim_set_hl(0, '@org.keyword.todo', { fg = '#f7a49c' })
      overrides = {
        Folded = {
          fg = c.lightgray,
          bg = c.winter.mantle,
          -- style = { 'italic' },
        },

        Keyword = config.highlights.keyword,
        ['@keyword'] = config.highlights.keyword,
        ['@keyword.coroutine'] = config.highlights.keyword,
        ['@keyword.operator'] = config.highlights.keyword,
        ['@annotation'] = config.highlights.keyword,

        IncSearch = { bg = c.orange, fg = c.black }, -- highlight on yank
        WinSeparator = { fg = c.gray },

        ['@comment'] = { fg = c.gray, style = { 'italic' } },
        ['@operator'] = { fg = c.lightgray, style = { 'bold' } },

        ['@function'] = { c.green, style = { 'bold' } },
        ['@lsp.typemod.function.declaration.javascript'] = { c.lime, style = { 'bold' } },
        ['@constant'] = { c.white, style = { 'italic' } },
        ['@lsp.mod.readonly.javascript'] = { c.white, style = { 'nocombine' } },

        ['@module'] = { c.blue, style = { 'nocombine' } },
        -- ['@variable.member'] = { colors.snow, style = { 'nocombine' } },

        ['@function.builtin.go'] = { c.white, style = { 'nocombine' } },
        ['@type.definition.go'] = { fg = c.yellow, style = { 'nocombine' } },
        ['@variable.builtin.typescript'] = { c.white, style = { 'nocombine' } },
        -- ['@keyword.import.typescript'] = { colors.blue, style = { 'nocombine' } },

        ['@lsp.mod.readonly.typescript'] = { c.white, style = { 'nocombine' } },
        ['@attribute.typescript'] = { c.white, style = { 'nocombine' } },
        -- ['@variable.parameter.typescript'] = { colors.white, style = { 'bold' } },

        Type = config.highlights.type,
        ['@type'] = config.highlights.type,

        ['@markup.raw'] = { fg = '#AFDFE6' }, -- inline `code` in markdown

        ['@markup.link.label.markdown_inline'] = { fg = c.blue }, -- inline `code` in markdown
        MarkviewPalette7Fg = { fg = c.blue, style = { 'underline' } }, -- markview inline hint
        SpellBad = { style = { 'italic', 'underdotted' } }, -- spelling mistakes
        SpellCap = { style = {} }, -- style when a word should start with a capital letter
        TabLineSel = { fg = c.green, bg = c.inactivegray, style = { 'bold' } },

        LineNrAbove = { fg = c.gray },
        LineNrBelow = { fg = c.gray },
        AvanteInlineHint = { fg = c.lightgray },
        -- MarkviewHeading1 = { fg = colors.white, bg = darken(colors.gray, 0.3), style = { "bold" } },
        -- ["@markup.heading.1.markdown"] = { fg = colors.white, bg = darken(colors.gray, 0.3), style = { "bold" } },
        -- MarkviewHeading2 = { fg = lighten(colors.subtext, 0.1), bg = darken(colors.gray, 0.3), style = { 'bold' } },
        -- ["@markup.heading.2.markdown"] = {
        --   fg = lighten(colors.blue, 0.1),
        --   bg = darken(colors.gray, 0.3),
        --   style = { "bold" },
        -- },
        -- MarkviewHeading3 = { fg = colors.lightgray, bg = darken(colors.gray, 0.4), style = { 'bold' } },
        -- ['@markup.heading.3.markdown'] = { fg = colors.lightgray, bg = darken(colors.gray, 0.4), style = { 'bold' } },
        DiffAdd = { fg = c.green, bg = c.comment }, -- markview heading 1
        DiffChange = { fg = c.green, bg = c.gray }, -- markview heading 1
        Underlined = { style = { 'underline', 'italic' } },
        LspReferenceRead = { bg = c.gray },
        LspReferenceText = { bg = c.gray },

        -- orgmode
        ['@org.plan.org'] = { fg = c.gray },
        ['@org.headline.level1.org'] = { fg = c.white, style = { 'bold' } },
        ['@org.headline.level2.org'] = { fg = c.subtext, style = { 'bold' } },
        ['@org.headline.level3.org'] = { fg = c.white, style = { 'nocombine' } },
        ['@org.headline.level4.org'] = { fg = c.white, style = { 'nocombine' } },
        ['@org.timestamp.active.org'] = { fg = c.light_red },
        ['@org.agenda.day'] = { fg = c.light_red },
        -- ['@org.agenda.scheduled'] = { fg = colors.lime },
        ['@org.keyword.active.org'] = { fg = c.light_red },
        ['@org.keyword.todo'] = { fg = c.red, style = { 'bold' } },
        ['@org.keyword.done'] = { fg = c.green, style = { 'bold' } },
        ['@org.tag.org'] = { fg = c.purple },
        ['@org.hyperlink.org'] = { fg = c.blue, style = { 'underline' } },
        ['@org.hyperlink.url.org'] = { style = { 'italic' } },
        ['@org.hyperlink.desc.org'] = { fg = c.blue, style = { 'italic' } },
        ['@org.priority.highest.org'] = { fg = c.orange, style = { 'italic' } },

        BlinkCmpMenu = { bg = c.base },
        BlinkCmpMenuBorder = { bg = c.base, fg = c.lightgray },
        FlashLabel = { bg = c.orange, fg = c.black },
        FlashCurrent = { bg = c.yellow, fg = c.black },
        SupermavenSuggestion = config.highlights.comment,
        -- lua
        -- ['@lsp.typemod.variable.defaultLibrary.lua'] = { fg = colors.blue, style = { 'nocombine' } },
        -- ['@lsp.typemod.function.defaultLibrary.lua'] = { fg = colors.blue, style = { 'nocombine' } },

        DiagnosticUnderlineError = { fg = c.light_red, style = { 'undercurl' } },
      },
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
          diff = true,
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
        telescope = true,
        which_key = true,
      },
    },
  },
}

-- NOTE: 2025-07-02
-- today I have green as the main accent color
-- someday I can change it to another lovely color
