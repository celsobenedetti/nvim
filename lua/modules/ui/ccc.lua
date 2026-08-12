return {
  'https://github.com/uga-rosa/ccc.nvim',
  cmd = {
    'CccPick',
    'CccConvert',
    'CccHighlighterEnable',
    'CccHighlighterDisable',
    'CccHighlighterToggle',
  },
  config = function()
    require('ccc').setup({
      inputs = { require('ccc.input.hsv') },
    })
  end,
}
