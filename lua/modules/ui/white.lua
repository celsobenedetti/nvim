return {
  'bjarneo/white.nvim',
  priority = 1000,
  dependencies = { { 'esmuellert/codediff.nvim' } },
  config = function()
    require('white').setup()

    vim.schedule(function()
      local colors = vim.g.colors
      colors.red = colors.color1
      colors.green = colors.color2
      colors.orange = colors.color3
      colors.light_orange = '#FAE1C8' -- hsv(30, 20%, 98%)
      colors.light_yellow = '#FAFAC8' -- hsv(60, 20%, 98%)
      colors.light_cyan = '#C8FAFA' -- hsv(180, 20%, 98%)
      colors.light_green = '#D4FAD4' -- hsv(120, 15%, 98%)
      colors.light_blue = '#D4D4FA' -- hsv(240, 15%, 98%)
      colors.light_purple = '#EDD4FA' -- hsv(280, 15%, 98%)
      colors.light_pink = '#FAD4ED' -- hsv(320, 15%, 98%)
      colors.light_red = '#FAD4D4' -- hsv(360, 15%, 98%)
      colors.light_gray = '#E6E4DF'
      colors.secondary = '#595855'

      -- vim.api.nvim_set_hl(0, 'ColorColumn', { bg = 'None' })
      -- vim.api.nvim_set_hl(0, 'Constant', { bg = 'None' })
      -- vim.api.nvim_set_hl(0, 'Statement', { bg = colors.light_red })
      -- vim.api.nvim_set_hl(0, 'String', { fg = colors['green'] })
      vim.api.nvim_set_hl(0, 'GitSignsAdd', { fg = colors['green'], bg = 'None' })
      vim.api.nvim_set_hl(0, 'GitSignsChange', { fg = colors['orange'], bg = 'None' })
      vim.api.nvim_set_hl(0, 'GitSignsDelete', { fg = colors['red'], bg = 'None' })
      vim.api.nvim_set_hl(0, 'GitSignsStagedAdd', { fg = colors['light_green'], bg = 'None' })
      vim.api.nvim_set_hl(0, 'GitSignsStagedChange', { fg = colors['light_orange'], bg = 'None' })
      vim.api.nvim_set_hl(0, 'GitSignsStagedDelete', { fg = colors['light_red'], bg = 'None' })
      vim.api.nvim_set_hl(0, 'EchoNotificationInfo', { fg = colors['base0'] })
      vim.api.nvim_set_hl(0, 'NotificationError', { fg = colors['base0'] })
      vim.api.nvim_set_hl(0, 'GitConflictAncestor', { bg = '#FAD4ED' })
      vim.api.nvim_set_hl(0, 'GitConflictCurrent', { bg = '#C8FAFA' })
      vim.api.nvim_set_hl(0, 'GitConflictIncoming', { bg = '#D4FAD4' })

      vim.api.nvim_set_hl(0, 'CodeDiffLineInsert', { bg = colors.light_green })
      vim.api.nvim_set_hl(0, 'CodeDiffLineDelete', { bg = colors.light_red })
      vim.api.nvim_set_hl(0, 'CodeDiffLineMove', { bg = colors.light_yellow })
      vim.api.nvim_set_hl(0, 'CodeDiffCharInsert', { bg = colors.light_green })
      vim.api.nvim_set_hl(0, 'CodeDiffCharDelete', { bg = colors.light_red })
      vim.api.nvim_set_hl(0, 'CodeDiffCharMove', { bg = colors.light_yellow })
      vim.api.nvim_set_hl(0, 'CodeDiffMoveFrom', { bg = colors.light_cyan })
      vim.api.nvim_set_hl(0, 'CodeDiffMoveTo', { bg = colors.light_cyan })
      vim.api.nvim_set_hl(0, 'CodeDiffFiller', { bg = colors.light_gray })
      -- vim.api.nvim_set_hl(0, 'CodeDiffExplorerSelected', { bg = colors.light_blue })
      vim.api.nvim_set_hl(0, 'ExplorerDirectorySmall', { bg = colors.light_gray })
      vim.api.nvim_set_hl(0, 'NeoTreeIndentMarker', { bg = colors.light_gray })
      -- vim.api.nvim_set_hl(0, 'CodeDiffExplorerTreeGroup', { bg = colors.light_purple })
      vim.api.nvim_set_hl(0, 'CodeDiffStatusAdded', { bg = colors.light_green })
      vim.api.nvim_set_hl(0, 'CodeDiffStatusModified', { bg = colors.light_yellow })
      vim.api.nvim_set_hl(0, 'CodeDiffStatusDeleted', { bg = colors.light_red })
      vim.api.nvim_set_hl(0, 'CodeDiffStatusRenamed', { bg = colors.light_blue })
      vim.api.nvim_set_hl(0, 'CodeDiffStatusUntracked', { bg = colors.light_pink })
      vim.api.nvim_set_hl(0, 'CodeDiffStatusConflict', { bg = colors.light_red })
      vim.api.nvim_set_hl(0, 'CodeDiffConflictSign', { bg = colors.light_orange })
      vim.api.nvim_set_hl(0, 'CodeDiffConflictSignResolved', { bg = colors.light_gray })
      vim.api.nvim_set_hl(0, 'CodeDiffConflictSignAccepted', { bg = colors.light_green })
      vim.api.nvim_set_hl(0, 'CodeDiffConflictSignRejected', { bg = colors.light_red })

      vim.g.colors = colors
    end)
  end,
}
