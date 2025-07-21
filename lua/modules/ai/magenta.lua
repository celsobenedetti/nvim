return {
  {
    'dlants/magenta.nvim',
    -- lazy = false, -- you could also bind to <leader>mt
    keys = {
      { '<leader>mt', '<cmd>Magenta toggle<cr>', desc = 'Magenta' },
    },
    build = 'npm install --frozen-lockfile',
    config = function()
      require('magenta').setup {
        profiles = {
          -- {
          --   name = 'claude-4',
          --   provider = 'anthropic',
          --   model = 'claude-4-sonnet-latest',
          --   fastModel = 'claude-3-5-haiku-latest', -- optional, defaults provided
          --   apiKeyEnvVar = 'ANTHROPIC_API_KEY',
          -- },
          {
            name = 'gpt-4.1',
            provider = 'openai',
            model = 'gpt-4.1',
            fastModel = 'gpt-4o-mini', -- optional, defaults provided
            apiKeyEnvVar = 'OPENAI_API_KEY',
          },
          -- {
          --   name = 'copilot-claude',
          --   provider = 'copilot',
          --   model = 'claude-3.7-sonnet',
          --   fastModel = 'claude-3-5-haiku-latest', -- optional, defaults provided
          --   -- No apiKeyEnvVar needed - uses existing Copilot authentication
          -- },
        },
        -- open chat sidebar on left or right side
        sidebarPosition = 'left',
        -- can be changed to "telescope" or "snacks"
        picker = 'telescope',
        -- enable default keymaps shown below
        defaultKeymaps = true,
        -- maximum number of sub-agents that can run concurrently (default: 3)
        maxConcurrentSubagents = 3,
        -- glob patterns for files that should be auto-approved for getFile tool
        -- (bypasses user approval for hidden/gitignored files matching these patterns)
        getFileAutoAllowGlobs = { 'node_modules/*' }, -- default includes node_modules
        -- keymaps for the sidebar input buffer
        sidebarKeymaps = {
          normal = {
            ['<CR>'] = ':Magenta send<CR>',
          },
        },
        -- keymaps for the inline edit input buffer
        -- if keymap is set to function, it accepts a target_bufnr param
        inlineKeymaps = {
          normal = {
            ['<CR>'] = function(target_bufnr)
              vim.cmd('Magenta submit-inline-edit ' .. target_bufnr)
            end,
          },
        },
        -- configure MCP servers for external tool integrations
        -- mcpServers = {
        --   fetch = {
        --     command = 'uvx',
        --     args = { 'mcp-server-fetch' },
        --   },
        --   playwright = {
        --     command = 'npx',
        --     args = {
        --       '@playwright/mcp@latest',
        --     },
        --   },
        --   -- HTTP-based MCP server example
        --   httpServer = {
        --     url = 'http://localhost:8000/mcp',
        --     requestInit = {
        --       headers = {
        --         Authorization = 'Bearer your-token-here',
        --       },
        --     },
        --   },
        -- },
      }
    end,
  },
}
