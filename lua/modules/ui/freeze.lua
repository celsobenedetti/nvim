return {
  {
    'charm-and-friends/freeze.nvim',
    cmd = { 'Freeze' },
    config = function()
      require('freeze').setup {
        command = 'freeze',
        open = true, -- Open the generated image after running the command
        output = function()
          return './' .. os.date '%Y-%m-%d' .. '_freeze.png'
        end,
        window = true,
        theme = C.ui.colorscheme,
        show_line_numbers = true,
        border = {
          width = 1,
          color = '#515151',
          radius = 8,
        },
      }
    end,
  },
}
