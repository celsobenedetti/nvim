return {
  {
    'mfussenegger/nvim-dap',
    keys = {
      {
        '<leader>bC',
        function()
          require('dap').clear_breakpoints()
          LazyVim.notify 'DAP breakpoints cleared'
        end,
        desc = 'DAP: Clear Breakpoints',
      },
      {
        '<leader>bL',
        function()
          require('dap').list_breakpoints(true)
        end,
        desc = 'DAP List Breakpoints',
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
    },
  },

  {
    'rcarriga/nvim-dap-ui',

    opts = {
      layouts = {
        {
          -- You can change the order of elements in the sidebar
          elements = {
            -- Provide IDs as strings or tables with "id" and "size" keys
            { id = 'scopes', size = 0.25 },
            { id = 'breakpoints', size = 0.25 },
            { id = 'stacks', size = 0.25 },
            { id = 'repl', size = 0.25 },
            { id = 'watches', size = 0.25 },
          },
          size = 40,
          position = 'left', -- Can be "left" or "right"
        },
        -- {
        --   elements = {
        --     'repl',
        --     'console',
        --   },
        --   size = 10,
        --   position = 'bottom', -- Can be "bottom" or "top"
        -- },
      },
    },
  },
}
