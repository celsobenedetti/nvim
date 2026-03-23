-- local bg = '#232A2E' -- evergarden
local bg = '#FAF2EB' -- deepwhite

return {
  {
    'folke/snacks.nvim',
    keys = {
      {
        '<leader>tw',
        function()
          MiniHipatterns.toggle()
          if Snacks.dim.enabled then
            Snacks.dim.disable()
            Snacks.indent.enable()
            vim.cmd('Gitsigns attach')
          else
            Snacks.indent.disable()
            Snacks.dim.enable({
              scope = {
                min_size = 5,
                max_size = 20,
              },
            })
            vim.cmd('Gitsigns detach')
          end
        end,
        desc = 'toggle dim',
      },
    },
    opts = function(_, opts)
      --- @type snacks.zen.Config
      opts.dim = {
        scope = {
          min_size = 1,
          max_size = 1,
          siblings = false,
        },
      }

      opts.scope = {
        treesitter = {
          enabled = true,
          injections = true,
          blocks = {
            enabled = false, -- enable to use the following blocks
            'function_declaration',
            'function_definition',
            'method_declaration',
            'method_definition',
            'class_declaration',
            'class_definition',
            'do_statement',
            'while_statement',
            'repeat_statement',
            'if_statement',
            'for_statement',
            'subsection',
            'drawer',
          },
          field_blocks = {
            'subsection',
          },
        },
      }

      vim.api.nvim_set_hl(0, 'SnacksDim', { bg = 'none', fg = bg })
    end,
  },
}
