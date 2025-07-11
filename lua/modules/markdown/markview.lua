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
          headings = presets.headings.glow,
          horizontal_rules = {
            enable = true,
            parts = {
              {
                type = 'repeating',
                repeat_amount = function(buffer)
                  local textoff = vim.fn.getwininfo(vim.api.nvim_get_current_win())[1].textoff
                  return math.floor((vim.o.columns - textoff - 3) / 3)
                end,
                text = '─',
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
                direction = 'right',
              },
              {
                type = 'text',
                text = '  ',
                hl = 'MarkviewGradient10',
              },
            },
          },
          block_quotes = {
            enable = true,
            default = {
              border = '▋',
              hl = 'MarkviewBlockQuoteDefault',
            },
            callouts = {
              {
                match_string = 'ABSTRACT',
                hl = 'MarkviewBlockQuoteNote',
                preview = '󱉫 Abstract',
                preview_hl = nil,
                title = true,
                icon = '󱉫 ',
                border = '▋',
                border_hl = nil,
              },
            },
          },

          list_items = {
            enable = true,
            wrap = true,
            indent_size = function(buffer)
              return 1
            end,
            shift_width = 1,

            marker_minus = {
              add_padding = false,
              conceal_on_checkboxes = true,

              text = '•',
              hl = 'MarkviewListItemMinus',
            },

            marker_plus = {
              add_padding = true,
              conceal_on_checkboxes = true,

              text = '◈',
              hl = 'MarkviewListItemPlus',
            },

            marker_star = {
              add_padding = true,
              conceal_on_checkboxes = true,

              text = '◇',
              hl = 'MarkviewListItemStar',
            },

            marker_dot = {
              add_padding = true,
              conceal_on_checkboxes = true,
            },

            marker_parenthesis = {
              add_padding = true,
              conceal_on_checkboxes = true,
            },
          },
        },

        markdown_inline = {
          hyperlinks = {

            ['github'] = {
              priority = 9999,
              icon = ' ', -- github
              hl = 'MarkviewPalette2Fg',
            },
            ['atlassian.net/wiki'] = {
              priority = 9999,
              icon = ' ', -- confluence
              hl = 'MarkviewPalette2Fg',
            },
            ['atlassian.net'] = {
              priority = 9998,
              icon = ' ', -- jira
              hl = 'MarkviewPalette2Fg',
            },
            ['awsapps'] = {
              priority = 9998,
              icon = '  ', -- aws
              hl = 'MarkviewPalette2Fg',
            },
            ['docs.google'] = {
              priority = 9998,
              icon = ' 󰈙 ', -- google docs
              hl = 'MarkviewPalette2Fg',
            },
            ['drive.google'] = {
              priority = 9998,
              icon = '  ', -- google drive
              hl = 'MarkviewPalette2Fg',
            },
            ['figma'] = {
              priority = 9998,
              icon = ' ', -- figma
              hl = 'MarkviewPalette2Fg',
            },

            ['cloud.mongodb'] = {
              priority = 9998,
              icon = ' ', -- mongo
              hl = 'MarkviewPalette2Fg',
            },
          },

          internal_links = {
            enable = true,
            default = {
              icon = '󰂺 ',
              hl = 'MarkviewPalette7Fg',
            },
          },
        },
      }
    end,
    keys = { { '<leader>md', ':Markview toggle<CR>', desc = 'Toggle markview' } },
  },
}
