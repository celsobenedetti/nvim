local config = {
  -- TODO: use vim.extend_table to extend these configs

  highlights = {
    keyword = { fg = vim.g.colors.red, style = { "nocombine" } },
    type = { vim.g.colors.yellow, style = { "nocombine" } },
    comment = { fg = vim.g.colors.gray, style = { "italic" } },
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
          fg = vim.g.colors.lightgray,
          bg = vim.g.colors.winter.mantle,
          -- style = { 'italic' },
        },

        Keyword = config.highlights.keyword,
        ["@keyword"] = config.highlights.keyword,
        ["@keyword.coroutine"] = config.highlights.keyword,
        ["@keyword.operator"] = config.highlights.keyword,
        ["@annotation"] = config.highlights.keyword,

        -- highlight on yank
        IncSearch = { bg = vim.g.colors.orange, fg = vim.g.colors.black },

        ["@comment"] = { fg = vim.g.colors.gray, style = { "italic" } },
        ["@operator"] = { fg = vim.g.colors.lightgray, style = { "bold" } },

        ["@function"] = { vim.g.colors.green, style = { "bold" } },
        ["@lsp.typemod.function.declaration.javascript"] = { vim.g.colors.lime, style = { "bold" } },
        ["@constant"] = { vim.g.colors.white, style = { "italic" } },
        ["@lsp.mod.readonly.javascript"] = { vim.g.colors.white, style = { "nocombine" } },

        ["@module"] = { vim.g.colors.blue, style = { "nocombine" } },
        -- ['@variable.member'] = { vim.g.colors.snow, style = { 'nocombine' } },

        ["@function.builtin.go"] = { vim.g.colors.white, style = { "nocombine" } },
        ["@type.definition.go"] = { fg = vim.g.colors.yellow, style = { "nocombine" } },
        ["@variable.builtin.typescript"] = { vim.g.colors.white, style = { "nocombine" } },
        -- ['@keyword.import.typescript'] = { vim.g.colors.blue, style = { 'nocombine' } },

        ["@lsp.mod.readonly.typescript"] = { vim.g.colors.white, style = { "nocombine" } },
        ["@attribute.typescript"] = { vim.g.colors.white, style = { "nocombine" } },
        -- ['@variable.parameter.typescript'] = { vim.g.colors.white, style = { 'bold' } },

        Type = config.highlights.type,
        ["@type"] = config.highlights.type,

        ["@markup.raw"] = { fg = "#AFDFE6" }, -- inline `code` in markdown

        ["@markup.link.label.markdown_inline"] = { fg = vim.g.colors.blue }, -- inline `code` in markdown
        MarkviewPalette7Fg = { fg = vim.g.colors.blue, style = { "underline" } }, -- markview inline hint
        SpellBad = { style = { "italic", "underdotted" } }, -- spelling mistakes
        SpellCap = { style = {} }, -- style when a word should start with a capital letter
        TabLineSel = { fg = vim.g.colors.green, bg = vim.g.colors.inactivegray, style = { "bold" } },

        LineNrAbove = { fg = vim.g.colors.gray },
        LineNrBelow = { fg = vim.g.colors.gray },
        AvanteInlineHint = { fg = vim.g.colors.lightgray },
        -- MarkviewHeading1 = { fg = vim.g.colors.white, bg = darken(vim.g.colors.gray, 0.3), style = { "bold" } },
        -- ["@markup.heading.1.markdown"] = { fg = vim.g.colors.white, bg = darken(vim.g.colors.gray, 0.3), style = { "bold" } },
        -- MarkviewHeading2 = { fg = lighten(vim.g.colors.subtext, 0.1), bg = darken(vim.g.colors.gray, 0.3), style = { 'bold' } },
        -- ["@markup.heading.2.markdown"] = {
        --   fg = lighten(vim.g.colors.blue, 0.1),
        --   bg = darken(vim.g.colors.gray, 0.3),
        --   style = { "bold" },
        -- },
        -- MarkviewHeading3 = { fg = vim.g.colors.lightgray, bg = darken(vim.g.colors.gray, 0.4), style = { 'bold' } },
        -- ['@markup.heading.3.markdown'] = { fg = vim.g.colors.lightgray, bg = darken(vim.g.colors.gray, 0.4), style = { 'bold' } },
        DiffAdd = { fg = vim.g.colors.green, bg = vim.g.colors.comment }, -- markview heading 1
        DiffChange = { fg = vim.g.colors.green, bg = vim.g.colors.gray }, -- markview heading 1
        Underlined = { style = { "underline", "italic" } },
        LspReferenceRead = { bg = vim.g.colors.gray },
        LspReferenceText = { bg = vim.g.colors.gray },

        -- orgmode
        ["@org.plan.org"] = { fg = vim.g.colors.gray },
        ["@org.headline.level1.org"] = { fg = vim.g.colors.white, style = { "bold" } },
        ["@org.headline.level2.org"] = { fg = vim.g.colors.subtext, style = { "bold" } },
        ["@org.headline.level3.org"] = { fg = vim.g.colors.white, style = { "nocombine" } },
        ["@org.headline.level4.org"] = { fg = vim.g.colors.white, style = { "nocombine" } },
        ["@org.timestamp.active.org"] = { fg = vim.g.colors.light_red },
        ["@org.agenda.day"] = { fg = vim.g.colors.light_red },
        -- ['@org.agenda.scheduled'] = { fg = vim.g.colors.lime },
        ["@org.keyword.active.org"] = { fg = vim.g.colors.light_red },
        ["@org.keyword.todo"] = { fg = vim.g.colors.red, style = { "bold" } },
        ["@org.keyword.done"] = { fg = vim.g.colors.green, style = { "bold" } },
        ["@org.tag.org"] = { fg = vim.g.colors.purple },
        ["@org.hyperlink.org"] = { fg = vim.g.colors.blue, style = { "underline" } },
        ["@org.hyperlink.url.org"] = { style = { "italic" } },
        ["@org.hyperlink.desc.org"] = { fg = vim.g.colors.blue, style = { "italic" } },
        ["@org.priority.highest.org"] = { fg = vim.g.colors.orange, style = { "italic" } },

        BlinkCmpMenu = { bg = vim.g.colors.base },
        BlinkCmpMenuBorder = { bg = vim.g.colors.base, fg = vim.g.colors.lightgray },
        FlashLabel = { bg = vim.g.colors.orange, fg = vim.g.colors.black },
        FlashCurrent = { bg = vim.g.colors.yellow, fg = vim.g.colors.black },
        SupermavenSuggestion = config.highlights.comment,
        -- lua
        -- ['@lsp.typemod.variable.defaultLibrary.lua'] = { fg = vim.g.colors.blue, style = { 'nocombine' } },
        -- ['@lsp.typemod.function.defaultLibrary.lua'] = { fg = vim.g.colors.blue, style = { 'nocombine' } },

        DiagnosticUnderlineError = { fg = vim.g.colors.lightgray, style = { "nocombine" } },
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
