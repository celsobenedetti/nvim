-- recommended: views can only be fully collapsed with the global statusline
vim.opt.laststatus = 3

return {
  {
    'yetone/avante.nvim',
    lazy = true,
    version = false, -- set this if you want to always pull the latest change
    keys = {

      { '<leader>aa', 'AvanteAsk', desc = 'AvanteAsk' },
      { '<leader>ae', 'AvanteEdit', desc = 'AvanteEdit' },
      { '<leader>ar', 'AvanteRefresh', desc = 'AvanteRefresh' },
      { '<leader>aC', 'AvanteClear', desc = 'AvanteClear' },
    },
    opts = {
      provider = 'openai',
      model = 'chatgpt-4o-latest',
      -- mappings = {
      --   ask = "<leader>aa", -- ask
      --   edit = "<leader>ae", -- edit
      --   refresh = "<leader>ar", -- refresh
      --   clear = "<leader>aC", -- clear
      -- },

      override_prompt_dir = function()
        return vim.fn.expand '~/.config/ai-rules/avante'
      end,
    },

    -- if you want to build from source then do `make BUILD_FROM_SOURCE=true`
    build = 'make',
    -- build = "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false" -- for windows
    dependencies = {
      'stevearc/dressing.nvim',
      'nvim-lua/plenary.nvim',
      'MunifTanjim/nui.nvim',
      --- The below dependencies are optional,
      'hrsh7th/nvim-cmp', -- autocompletion for avante commands and mentions
      'nvim-tree/nvim-web-devicons', -- or echasnovski/mini.icons
      -- 'zbirenbaum/copilot.lua', -- for providers='copilot'
      -- {
      --   -- Make sure to set this up properly if you have lazy=true
      --   'MeanderingProgrammer/render-markdown.nvim',
      --   opts = {
      --     file_types = { 'Avante' },
      --   },
      --   ft = { 'markdown', 'Avante' },
      -- },
    },
  },
}
