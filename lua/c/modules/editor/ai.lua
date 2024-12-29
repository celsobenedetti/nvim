return {
  -- {
  --   'zbirenbaum/copilot.lua',
  --   enabled = vim.g.copilot,
  --   event = 'VeryLazy',
  --   opts = {
  --     filetypes = {
  --       yaml = true,
  --       json = true,
  --     },
  --     suggestion = { enabled = false },
  --     panel = { enabled = false },
  --   },
  -- },
  --
  -- {
  --   'zbirenbaum/copilot-cmp',
  --   enabled = vim.g.copilot,
  --   dependencies = { 'zbirenbaum/copilot.lua' },
  --   config = function()
  --     require('copilot_cmp').setup()
  --   end,
  -- },

  {
    'robitx/gp.nvim',
    cmd = {
      'GpChatNew',
    },
    keys = {
      {
        '<leader>G',
        ':GpChatNew tabnew<CR>',
        desc = 'Open ChatGPT in new tab',
      },
    },
    config = function()
      require('gp').setup()
    end,
  },

  {
    'piersolenski/wtf.nvim',
    dependencies = {
      'MunifTanjim/nui.nvim',
    },
    opts = {},
    keys = {
      {
        'gw',
        mode = { 'n', 'x' },
        function()
          require('wtf').ai()
        end,
        desc = 'Debug diagnostic with AI',
      },
      {
        mode = { 'n' },
        'gW',
        function()
          require('wtf').search()
        end,
        desc = 'Search diagnostic with Google',
      },
    },
  },

  {
    'yetone/avante.nvim',
    event = 'VeryLazy',
    lazy = false,
    keys = {
      {
        '<leader>A',
        ':AvanteAsk<CR>',
        desc = 'Avante GenAI Prompt',
      },
    },
    version = false, -- set this if you want to always pull the latest change
    opts = {
      provider = 'openai',
      model = 'chatgpt-4o-latest',
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
      'zbirenbaum/copilot.lua', -- for providers='copilot'
      {
        -- Make sure to set this up properly if you have lazy=true
        'MeanderingProgrammer/render-markdown.nvim',
        opts = {
          file_types = { 'markdown', 'Avante' },
        },
        ft = { 'markdown', 'Avante' },
      },
    },
  },
}
