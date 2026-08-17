return {
  'https://github.com/uga-rosa/ccc.nvim',
  cmd = {
    'CccPick',
    'CccConvert',
  },
  config = function()
    require('ccc').setup({
      inputs = { require('ccc.input.hsv') },
      alpha_show = 'hide',
      mappings = { ['a'] = function() end },
    })
  end,
}
