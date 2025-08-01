return {
  {
    "mfussenegger/nvim-dap",
    keys = {
      {
        "<leader>bC",
        function()
          require("dap").clear_breakpoints()
          LazyVim.notify("DAP breakpoints cleared")
        end,
        desc = "DAP: Clear Breakpoints",
      },
      {
        "<leader>bL",
        function()
          require("dap").list_breakpoints(true)
        end,
        desc = "DAP List Breakpoints",
      },
      {
        "<leader>do",
        function()
          require("dap").step_over()
        end,
        desc = "DAP: Step Over",
      },
      {
        "<leader>dO",
        function()
          require("dap").step_out()
        end,
        desc = "DAP: Step Out",
      },
    },
  },
}
