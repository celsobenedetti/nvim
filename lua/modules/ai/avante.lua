return {

  {
    'yetone/avante.nvim',
    event = 'VeryLazy',
    version = false, -- set this if you want to always pull the latest change
    opts = {
      provider = 'openai',
      model = 'chatgpt-4o-latest',
      -- provider = 'claude',
      -- mode = 'agentic',
      -- claude = {
      --   endpoint = 'https://api.anthropic.com',
      --   -- model = 'claude-3-5-sonnet-20241022',
      --   model = 'claude-sonnet-4-20250514',
      --   temperature = 0,
      --   max_tokens = 4096,
      -- },
      mappings = {
        ask = '<leader>aa', -- ask
        edit = '<leader>ae', -- edit
        refresh = '<leader>ar', -- refresh
        clear = '<leader>aC', -- clear
      },
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
