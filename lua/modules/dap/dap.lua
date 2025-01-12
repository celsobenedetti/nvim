---@diagnostic disable: undefined-field
return {
  {
    'mfussenegger/nvim-dap',
    dependencies = {
      'williamboman/mason.nvim', -- Installs the debug adapters for you
      'jay-babu/mason-nvim-dap.nvim',
      'theHamsta/nvim-dap-virtual-text',
    },
    keys = {
      {
        '<leader>dc',
        function()
          require('dap').continue()
        end,
        desc = 'DAP: Start/Continue',
      },
      {
        '<leader>dC',
        function()
          require('dap').run_to_cursor()
        end,
        desc = 'Run to Cursor',
      },
      {
        '<leader>di',
        function()
          require('dap').step_into()
        end,
        desc = 'DAP: Step Into',
      },
      {
        '<leader>do',
        function()
          require('dap').step_over()
        end,
        desc = 'DAP: Step Over',
      },
      {
        '<leader>dO',
        function()
          require('dap').step_out()
        end,
        desc = 'DAP: Step Out',
      },
      {
        '<leader>db',
        function()
          require('dap').toggle_breakpoint()
        end,
        desc = 'DAP: Toggle Breakpoint',
      },

      {
        '<leader>dB',
        function()
          require('dap').set_breakpoint(vim.fn.input 'Breakpoint condition: ')
        end,
        desc = 'DAP: Set Breakpoint',
      },

      -- Toggle to see last session result. Without this, you can't see session output in case of unhandled exception.
      {
        '<leader>bC',
        function()
          require('dap').clear_breakpoints()
        end,
        desc = 'Clear DAP Breakpoints',
      },
      {
        '<leader>bL',
        function()
          require('dap').list_breakpoints(true)
        end,
        desc = 'List DAP Breakpoints',
      },
      {
        '<leader>dt',
        function()
          require('dap').terminate()
        end,
        desc = 'DAP: Terminate',
      },
    },
    config = function()
      vim.fn.sign_define('DapBreakpoint', { text = '', texthl = '', linehl = '', numhl = '' })

      require('mason-nvim-dap').setup {
        automatic_installation = true,

        -- Makes a best effort to setup the various debuggers with
        -- reasonable debug configurations
        automatic_setup = true,

        -- You can provide additional configuration to the handlers,
        -- see mason-nvim-dap README for more information
        handlers = {},

        -- You'll need to check that you have the required things installed
        -- online, please don't ask me how to install them :)
        ensure_installed = {
          -- Update this to ensure that you have the debuggers for the langs you want
          'delve',
        },
      }

      require('nvim-dap-virtual-text').setup()

      local filetype = vim.api.nvim_get_option_value('filetype', {})
      if filetype == 'typescript' or filetype == 'javascript' then
        require 'modules.typescript.dap.setup'()
        return
      end

      if filetype == 'go' then
        -- Install golang specific config
        require('dap-go').setup {
          dap_configurations = {
            {
              type = 'go',
              name = 'Attach remote',
              mode = 'remote',
              request = 'attach',
              -- tell which host and port to connect to
              connect = {
                host = '127.0.0.1',
                port = '8181',
              },
            },
          },
          delve = {
            port = '8181',
          },
        }

        return
      end
    end,
  },
}
