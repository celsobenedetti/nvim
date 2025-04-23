-- https://github.com/OXY2DEV/markview.nvim
return {
  {
    'OXY2DEV/markview.nvim',
    -- lazy = false, -- Recommended
    ft = { 'markdown', 'Avante' }, -- If you decide to lazy-load anyway
    dependencies = {
      'nvim-treesitter/nvim-treesitter',
      'nvim-tree/nvim-web-devicons',
    },
    config = function()
      local presets = require 'markview.presets'

      require('markview').setup {
        -- horizontal_rules = presets.horizontal_rules.thin,
        checkboxes = presets.checkboxes.nerd,
        markdown = {
          headings = presets.headings.slanted,
          horizontal_rules = {
            enable = true,
            parts = {
              {
                type = 'repeating',

                --- Amount of time to repeat the text
                --- Can be an integer or a function.
                ---
                --- If the value is a function the "buffer" ID
                --- is provided as the parameter.
                ---@type integer | fun(buffer: integer): nil
                repeat_amount = function(buffer)
                  local textoff = vim.fn.getwininfo(vim.api.nvim_get_current_win())[1].textoff

                  return math.floor((vim.o.columns - textoff - 3) / 3)
                end,

                --- Text to repeat.
                ---@type string
                text = '─',

                --- Highlight group for this part.
                --- Can be a string(for solid color) or a
                --- list of string(for gradient)
                ---@type string[] | string
                hl = {
                  'MarkviewGradient1',
                  'MarkviewGradient2',
                  'MarkviewGradient3',
                  'MarkviewGradient4',
                  'MarkviewGradient5',
                  'MarkviewGradient6',
                  'MarkviewGradient7',
                  'MarkviewGradient8',
                  'MarkviewGradient9',
                  'MarkviewGradient10',
                },

                --- Placement direction of the gradient.
                ---@type "left" | "right"
                direction = 'right',
              },
              {
                type = 'text',
                text = '  ',

                ---@type string?
                hl = 'MarkviewGradient10',
              },
            },
          },

          block_quotes = {
            enable = true,

            --- Default configuration for block quotes.
            default = {
              --- Text to use as border for the block
              --- quote.
              --- Can also be a list if you want multiple
              --- border types!
              ---@type string | string[]
              border = '▋',

              --- Highlight group for "border" option. Can also
              --- be a list to create gradients.
              ---@type (string | string[])?
              hl = 'MarkviewBlockQuoteDefault',
            },

            --- Configuration for custom block quotes
            callouts = {
              {
                --- String between "[!" & "]"
                ---@type string
                match_string = 'ABSTRACT',

                --- Primary highlight group. Used by other options
                --- that end with "_hl" when their values are nil.
                ---@type string?
                hl = 'MarkviewBlockQuoteNote',

                --- Text to show in the preview.
                ---@type string
                preview = '󱉫 Abstract',

                --- Highlight group for the preview text.
                ---@type string?
                preview_hl = nil,

                --- When true, adds the ability to add a title
                --- to the block quote.
                ---@type boolean
                title = true,

                --- Icon to show before the title.
                ---@type string?
                icon = '󱉫 ',

                ---@type string | string
                border = '▋',

                ---@type (string | string[])?
                border_hl = nil,
              },
            },
          },
        },
      }
    end,
    keys = { { '<leader>md', ':Markview toggle<CR>', desc = 'Toggle markview' } },
  },
}
