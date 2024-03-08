-- debug.lua
--
-- Shows how to use the DAP plugin to debug your code.
--
-- Primarily focused on configuring the debugger for Go, but can
-- be extended to other languages as well. That's why it's called
-- kickstart.nvim and not kitchen-sink.nvim ;)

local ft = { 'typescript', 'javascript', 'go' }

return {
  {
    'mfussenegger/nvim-dap',
    ft = ft,
    dependencies = {

      'williamboman/mason.nvim', -- Installs the debug adapters for you
      'jay-babu/mason-nvim-dap.nvim',
      'leoluz/nvim-dap-go', -- Add your own debuggers here
    },
    keys = {
      {
        '<leader>dc',
        function()
          require('dap').continue()
        end,
        { desc = 'Debug: Start/Continue' },
      },
      {
        '<leade>di',
        function()
          require('dap').step_into()
        end,
        { desc = 'Debug: Step Into' },
      },
      {
        '<leader>do',
        function()
          require('dap').step_over()
        end,
        { desc = 'Debug: Step Over' },
      },
      {
        '<leader>dO',
        function()
          require('dap').step_out()
        end,
        { desc = 'Debug: Step Out' },
      },
      {
        '<leader>db',
        function()
          require('dap').toggle_breakpoint()
        end,
        { desc = 'Debug: Toggle Breakpoint' },
      },

      {
        '<leader>dB',
        function()
          require('dap').set_breakpoint(vim.fn.input 'Breakpoint condition: ')
        end,
        { desc = 'Debug: Set Breakpoint' },
      },

      -- Toggle to see last session result. Without this, you can't see session output in case of unhandled exception.
      {
        '<leader>du',
        function()
          require('dapui').toggle()
        end,
        { desc = 'Debug: See last session result.' },
      },
    },
    config = function()
      local dap = require 'dap'
      local dapui = require 'dapui'

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

      -- Basic debugging keymaps, feel free to change to your liking!

      -- Dap UI setup
      -- For more information, see |:help nvim-dap-ui|
      dapui.setup {
        -- Set icons to characters that are more likely to work in every terminal.
        --    Feel free to remove or use ones that you like more! :)
        --    Don't feel like these are good choices.
        icons = { expanded = '▾', collapsed = '▸', current_frame = '*' },
        controls = {
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
        },
      }

      dap.listeners.after.event_initialized['dapui_config'] = dapui.open
      dap.listeners.before.event_terminated['dapui_config'] = dapui.close
      dap.listeners.before.event_exited['dapui_config'] = dapui.close

      local filetype = vim.api.nvim_get_option_value('filetype', {})

      if filetype == 'typescript' or filetype == 'javascript' then
        require('plugins.dap.typescript').setup()
      end

      if filetype == 'go' then
        -- Install golang specific config
        require('dap-go').setup()
      end
    end,
  },

  {
    'rcarriga/nvim-dap-ui',
    ft = ft,
    opts = function(_, opts)
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
      -- code
    end,
  },
}
