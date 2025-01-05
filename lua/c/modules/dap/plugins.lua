-- debug.lua
--
-- Shows how to use the DAP plugin to debug your code.
--
-- Primarily focused on configuring the debugger for Go, but can
-- be extended to other languages as well. That's why it's called
-- kickstart.nvim and not kitchen-sink.nvim ;)

return {
  { 'leoluz/nvim-dap-go', ft = { 'go' } },

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
