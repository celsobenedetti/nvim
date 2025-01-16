-- WIP: This is an experiment. Probably not needed tbh
return {
  {
    'CopilotC-Nvim/CopilotChat.nvim',
    lazy = true,
    dependencies = {
      { 'zbirenbaum/copilot.lua' }, -- or zbirenbaum/copilot.lua
      { 'nvim-lua/plenary.nvim', branch = 'master' }, -- for curl, log and async functions
    },
    build = 'make tiktoken', -- Only on MacOS or Linux
    opts = {
      -- See Configuration section for options
    },
    -- See Commands section for default commands if you want to lazy load on them
    --
    keys = {
      { '<leader>cct', ':CopilotChatToggle<CR>', desc = 'CopilotChat - toggle' },
      {
        '<leader>cc',
        function()
          local input = vim.fn.input 'Quick Chat: '
          if input ~= '' then
            require('CopilotChat').ask(input, { selection = require('CopilotChat.select').buffer })
          end
        end,
        desc = 'CopilotChat - Quick chat',
      },
      {
        '<leader>cp',
        function()
          local actions = require 'CopilotChat.actions'
          require('CopilotChat.integrations.telescope').pick(actions.prompt_actions())
        end,
        desc = 'CopilotChat - Prompt actions',
        mode = { 'n', 'v' },
      },
    },
  },
}
