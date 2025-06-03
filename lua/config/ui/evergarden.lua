return {
  theme = {
    variant = 'fall', -- 'winter'|'fall'|'spring'|'summer'
    accent = 'green',
  },
  overrides = {
    Folded = {
      '#fddce3',
      '#1D2428',
      style = { 'italic' },
    },

    LineNrAbove = { fg = '#58686D' },
    LineNrBelow = { fg = '#58686D' },
  },
  integrations = {
    cmp = true,
    gitsigns = true,
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
    telescope = false,
    which_key = true,
  },
}
