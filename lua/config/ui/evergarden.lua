local config = {

  highlights = {
    keyword = { fg = C.ui.colors.red, style = { 'nocombine' } },
    type = { C.ui.colors.yellow, style = { 'nocombine' } },
  },
}

return {
  theme = {
    variant = 'winter', -- 'winter'|'fall'|'spring'|'summer'
    accent = 'green',
  },
  overrides = {
    Folded = {
      C.ui.colors.gray,
      C.ui.colors.black,
      -- style = { 'italic' },
    },

    Keyword = config.highlights.keyword,
    ['@keyword'] = config.highlights.keyword,
    ['@keyword.coroutine'] = config.highlights.keyword,
    ['@keyword.operator'] = config.highlights.keyword,

    ['@function'] = { C.ui.colors.lime, style = { 'bold' } },
    ['@constant'] = { C.ui.colors.white, style = { 'bold' } },
    ['@module'] = { C.ui.colors.blue, style = { 'nocombine' } },
    -- ['@variable.member'] = { C.ui.colors.snow, style = { 'nocombine' } },

    ['@function.builtin.go'] = { C.ui.colors.white, style = { 'nocombine' } },
    ['@variable.builtin.typescript'] = { C.ui.colors.white, style = { 'nocombine' } },
    ['@keyword.import.typescript'] = { C.ui.colors.blue, style = { 'nocombine' } },

    ['@lsp.mod.readonly.typescript'] = { C.ui.colors.white, style = { 'nocombine' } },
    ['@attribute.typescript'] = { C.ui.colors.white, style = { 'nocombine' } },

    Type = config.highlights.type,
    ['@type'] = config.highlights.type,

    ['@markup.raw'] = { fg = '#AFDFE6' }, -- inline `code` in markdown

    SpellBad = { fg = C.ui.colors.light_red, style = { 'undercurl', 'italic' } }, -- spelling mistakes
    SpellCap = { style = {} }, -- style when a word should start with a capital letter

    LineNrAbove = { fg = C.ui.colors.gray },
    LineNrBelow = { fg = C.ui.colors.gray },
    AvanteInlineHint = { fg = C.ui.colors.lightgray },
    MarkviewPalette7Fg = { fg = C.ui.colors.aqua, style = { 'underline' } }, -- markview inline hint
    MarkviewHeading1 = { fg = C.ui.colors.red, style = { 'bold' } }, -- markview heading 1
    DiffAdd = { fg = C.ui.colors.green, bg = C.ui.colors.comment }, -- markview heading 1
    -- DiagnosticUnderlineError this one is a little aggressive. I may change it in the future
    Underlined = { style = { 'underline', 'italic' } },
    LspReferenceRead = { bg = C.ui.colors.gray },
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
}
