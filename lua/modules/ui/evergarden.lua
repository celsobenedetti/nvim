local config = {
  -- TODO: use vim.extend_table to extend these configs

  highlights = {
    keyword = { fg = C.colors.red, style = { "nocombine" } },
    type = { C.colors.yellow, style = { "nocombine" } },
    comment = { fg = C.colors.gray, style = { "italic" } },
  },
}

return {

  {
    lazy = false,
    "everviolet/nvim",
    name = "evergarden",
    priority = 1000,
    opts = {

      theme = {
        variant = "fall", -- 'winter'|'fall'|'spring'|'summer'
        accent = "green",
      },

      --  example for API: vim.api.nvim_set_hl(0, '@org.keyword.todo', { fg = '#f7a49c' })
      overrides = {
        Folded = {
          fg = C.colors.lightgray,
          bg = C.colors.winter.mantle,
          -- style = { 'italic' },
        },

        Keyword = config.highlights.keyword,
        ["@keyword"] = config.highlights.keyword,
        ["@keyword.coroutine"] = config.highlights.keyword,
        ["@keyword.operator"] = config.highlights.keyword,
        ["@annotation"] = config.highlights.keyword,

        -- highlight on yank
        IncSearch = { bg = C.colors.orange, fg = C.colors.black },

        ["@comment"] = { fg = C.colors.gray, style = { "italic" } },
        ["@operator"] = { fg = C.colors.lightgray, style = { "bold" } },

        ["@function"] = { C.colors.green, style = { "bold" } },
        ["@lsp.typemod.function.declaration.javascript"] = { C.colors.lime, style = { "bold" } },
        ["@constant"] = { C.colors.white, style = { "italic" } },
        ["@lsp.mod.readonly.javascript"] = { C.colors.white, style = { "nocombine" } },

        ["@module"] = { C.colors.blue, style = { "nocombine" } },
        -- ['@variable.member'] = { C.colors.snow, style = { 'nocombine' } },

        ["@function.builtin.go"] = { C.colors.white, style = { "nocombine" } },
        ["@type.definition.go"] = { fg = C.colors.yellow, style = { "nocombine" } },
        ["@variable.builtin.typescript"] = { C.colors.white, style = { "nocombine" } },
        -- ['@keyword.import.typescript'] = { C.colors.blue, style = { 'nocombine' } },

        ["@lsp.mod.readonly.typescript"] = { C.colors.white, style = { "nocombine" } },
        ["@attribute.typescript"] = { C.colors.white, style = { "nocombine" } },
        -- ['@variable.parameter.typescript'] = { C.colors.white, style = { 'bold' } },

        Type = config.highlights.type,
        ["@type"] = config.highlights.type,

        ["@markup.raw"] = { fg = "#AFDFE6" }, -- inline `code` in markdown

        ["@markup.link.label.markdown_inline"] = { fg = C.colors.blue }, -- inline `code` in markdown
        MarkviewPalette7Fg = { fg = C.colors.blue, style = { "underline" } }, -- markview inline hint
        SpellBad = { style = { "italic", "underdotted" } }, -- spelling mistakes
        SpellCap = { style = {} }, -- style when a word should start with a capital letter
        TabLineSel = { fg = C.colors.green, bg = C.colors.inactivegray, style = { "bold" } },

        LineNrAbove = { fg = C.colors.gray },
        LineNrBelow = { fg = C.colors.gray },
        AvanteInlineHint = { fg = C.colors.lightgray },
        -- MarkviewHeading1 = { fg = C.colors.white, bg = darken(C.colors.gray, 0.3), style = { "bold" } },
        -- ["@markup.heading.1.markdown"] = { fg = C.colors.white, bg = darken(C.colors.gray, 0.3), style = { "bold" } },
        -- MarkviewHeading2 = { fg = lighten(C.colors.subtext, 0.1), bg = darken(C.colors.gray, 0.3), style = { 'bold' } },
        -- ["@markup.heading.2.markdown"] = {
        --   fg = lighten(C.colors.blue, 0.1),
        --   bg = darken(C.colors.gray, 0.3),
        --   style = { "bold" },
        -- },
        -- MarkviewHeading3 = { fg = C.colors.lightgray, bg = darken(C.colors.gray, 0.4), style = { 'bold' } },
        -- ['@markup.heading.3.markdown'] = { fg = C.colors.lightgray, bg = darken(C.colors.gray, 0.4), style = { 'bold' } },
        DiffAdd = { fg = C.colors.green, bg = C.colors.comment }, -- markview heading 1
        DiffChange = { fg = C.colors.green, bg = C.colors.gray }, -- markview heading 1
        Underlined = { style = { "underline", "italic" } },
        LspReferenceRead = { bg = C.colors.gray },

        -- orgmode
        ["@org.plan.org"] = { fg = C.colors.gray },
        ["@org.headline.level1.org"] = { fg = C.colors.white, style = { "bold" } },
        ["@org.headline.level2.org"] = { fg = C.colors.subtext, style = { "bold" } },
        ["@org.headline.level3.org"] = { fg = C.colors.white, style = { "nocombine" } },
        ["@org.headline.level4.org"] = { fg = C.colors.white, style = { "nocombine" } },
        ["@org.timestamp.active.org"] = { fg = C.colors.light_red },
        ["@org.agenda.day"] = { fg = C.colors.light_red },
        -- ['@org.agenda.scheduled'] = { fg = C.colors.lime },
        ["@org.keyword.active.org"] = { fg = C.colors.light_red },
        ["@org.keyword.todo"] = { fg = C.colors.red, style = { "bold" } },
        ["@org.keyword.done"] = { fg = C.colors.green, style = { "bold" } },
        ["@org.tag.org"] = { fg = C.colors.purple },
        ["@org.hyperlink.org"] = { fg = C.colors.blue, style = { "underline" } },
        ["@org.hyperlink.url.org"] = { style = { "italic" } },
        ["@org.hyperlink.desc.org"] = { fg = C.colors.blue, style = { "italic" } },
        ["@org.priority.highest.org"] = { fg = C.colors.orange, style = { "italic" } },

        BlinkCmpMenu = { bg = C.colors.base },
        BlinkCmpMenuBorder = { bg = C.colors.base, fg = C.colors.lightgray },
        FlashLabel = { bg = C.colors.orange, fg = C.colors.black },
        FlashCurrent = { bg = C.colors.gray, fg = C.colors.black },
        SupermavenSuggestion = config.highlights.comment,
        -- lua
        -- ['@lsp.typemod.variable.defaultLibrary.lua'] = { fg = C.colors.blue, style = { 'nocombine' } },
        -- ['@lsp.typemod.function.defaultLibrary.lua'] = { fg = C.colors.blue, style = { 'nocombine' } },

        DiagnosticUnderlineError = { fg = C.colors.lightgray, style = { "nocombine" } },
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
