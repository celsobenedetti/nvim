-- https://github.com/OXY2DEV/markview.nvim
return {
  {
    'MeanderingProgrammer/render-markdown.nvim',
    keys = { { '<leader>md', ':RenderMarkdown toggle<CR>', desc = 'Toggle render markdown' } },
    opts = {
      code = {
        sign = false,
        width = 'block',
        right_pad = 1,
      },
      heading = {
        sign = false,
        icons = {},
        border = false,
        border_virtual = false,
      },
      checkbox = {
        enabled = false,
      },
    },
    ft = { 'markdown', 'norg', 'rmd', 'org', 'codecompanion' },
    config = function(_, opts)
      require('render-markdown').setup(opts)
      Snacks.toggle({
        name = 'Render Markdown',
        get = require('render-markdown').get,
        set = require('render-markdown').set,
      }):map('<leader>um')
    end,
  },
}
