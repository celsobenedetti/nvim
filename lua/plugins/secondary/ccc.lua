return {
  'https://github.com/uga-rosa/ccc.nvim',
  cmd = {
    'CccPick',
    'PickColor',
  },
  config = function()
    require('ccc').setup({
      inputs = { require('ccc.input.hsv') },
      alpha_show = 'hide',
      mappings = { ['a'] = function() end },
    })

    vim.api.nvim_create_user_command('PickColor', function()
      vim.cmd('CccPick')
    end, { desc = 'Pick a color' })
  end,
}
