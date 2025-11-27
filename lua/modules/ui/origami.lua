return {
  {
    'chrisgrieser/nvim-origami',
    event = 'VeryLazy',
    enabled = vim.g.origami,
    opts = {
      -- default settings
      useLspFoldsWithTreesitterFallback = true, -- required for `autoFold`
      pauseFoldsOnSearch = true,
      foldtext = {
        enabled = false,
        padding = 3,
        lineCount = {
          template = '%d lines', -- `%d` is replaced with the number of folded lines
          hlgroup = 'Comment',
        },
        diagnosticsCount = true, -- uses hlgroups and icons from `vim.diagnostic.config().signs`
        gitsignsCount = true, -- requires `gitsigns.nvim`
      },
      autoFold = {
        enabled = false,
        kinds = { 'comment', 'imports' }, ---@type lsp.FoldingRangeKind[]
      },
      foldKeymaps = {
        setup = true, -- modifies `h` and `l`
        hOnlyOpensOnFirstColumn = true,
      },
    },

    -- recommended: disable vim's auto-folding
    init = function()
      vim.opt.foldlevel = 99
      vim.opt.foldlevelstart = 99
    end,
  },
}
