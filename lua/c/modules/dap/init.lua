-- debug.lua
--
-- Shows how to use the DAP plugin to debug your code.
--
-- Primarily focused on configuring the debugger for Go, but can
-- be extended to other languages as well. That's why it's called
-- kickstart.nvim and not kitchen-sink.nvim ;)

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
        require 'c.modules.typescript.dap.setup'()
        return
      end

      if filetype == 'go' then
        -- Install golang specific config
        require('dap-go').setup()
        return
      end
    end,
  },

  {
    'leoluz/nvim-dap-go', -- Add your own debuggers here
    ft = { 'go' },
  },

  {
    'rcarriga/nvim-dap-ui',
    dependencies = { 'mfussenegger/nvim-dap', 'nvim-neotest/nvim-nio' },
    keys = {
      {
        '<leader>du',
        function()
          require('dapui').toggle()
        end,
        desc = 'DAP: UI Toggle',
      },
    },
    config = function(_, opts)
      local dap = require 'dap'
      local dapui = require 'dapui'

      opts.icons = { expanded = '▾', collapsed = '▸', current_frame = '*' }
      opts.controls = {
        icons = {
          pause = '⏸',
          play = '▶',
          step_into = '⏎',
          step_over = '⏭',
          step_out = '⏮',
          step_back = 'b',
          run_last = '▶▶',
          terminate = '⏹',
          disconnect = '⏏',
        },
      }

      opts.layouts = {

        {
          elements = {
            {
              id = 'scopes',
              size = 0.25,
            },
            {
              id = 'breakpoints',
              size = 0.25,
            },
            {
              id = 'stacks',
              size = 0.25,
            },
            {
              id = 'watches',
              size = 0.25,
            },
          },
          position = 'left',
          size = 40,
        },

        {
          elements = {
            {
              id = 'repl',
              size = 1,
            },
          },
          position = 'bottom',
          size = 15,
        },
      }

      dapui.setup(opts)

      dap.listeners.after.event_initialized['dapui_config'] = dapui.open
      dap.listeners.before.event_terminated['dapui_config'] = dapui.close
      dap.listeners.before.event_exited['dapui_config'] = dapui.close
    end,
  },

  {
    'nvim-telescope/telescope-dap.nvim',
    dependencies = {
      'nvim-telescope/telescope.nvim',
    },
    config = function()
      pcall(require('telescope').load_extension, 'fzf')
    end,
    keys = {
      {
        '<leader>sb',
        function()
          require('telescope').extensions.dap.list_breakpoints()
        end,
        desc = 'DAP: [S]earch [B]reakpoints',
      },

      {
        '<leader>dv',
        function()
          require('telescope').extensions.dap.variables()
        end,
        desc = 'DAP: [S]earch [V]ariables',
      },
    },
  },
}
