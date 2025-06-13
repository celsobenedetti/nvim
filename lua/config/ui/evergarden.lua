return {
  theme = {
    variant = 'winter', -- 'winter'|'fall'|'spring'|'summer'
    accent = 'green',
  },
  overrides = {
    Folded = {
      '#6F8788',
      C.ui.colors.darkgray,
      style = { 'italic' },
    },

    ['@markup.raw'] = { fg = '#AFDFE6' }, -- inline `code` in markdown

    SpellBad = { fg = C.ui.colors.light_red, style = { 'undercurl', 'italic' } }, -- spelling mistakes
    SpellCap = { style = {} }, -- style when a word should start with a capital letter

    LineNrAbove = { fg = C.ui.colors.gray },
    LineNrBelow = { fg = C.ui.colors.gray },
    AvanteInlineHint = { fg = C.ui.colors.lightgray },
    MarkviewPalette7Fg = { fg = C.ui.colors.aqua, style = { 'underline' } }, -- markview inline hint
    MarkviewHeading1 = { fg = C.ui.colors.red, style = { 'bold' } }, -- markview heading 1
    DiffAdd = { fg = C.ui.colors.green, bg = C.ui.colors.inactivegray }, -- markview heading 1
    -- DiagnosticUnderlineError this one is a little aggressive. I may change it in the future
    Underlined = { style = { 'underline', 'italic' } },
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
