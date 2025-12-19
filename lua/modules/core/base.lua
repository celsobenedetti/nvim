---@module 'base' module with general core plugins

return {
  -- core plugins
  { 'neovim/nvim-lspconfig' }, -- install lspconfig through lazy.nvim
  { 'wakatime/vim-wakatime' }, -- code time tracking goodness

  -- json/yaml schema store
  { 'b0o/SchemaStore.nvim', lazy = true, ft = { 'json', 'yaml', 'toml' } },

  -- lua lsp intellisense for neovim config
  {
    'folke/lazydev.nvim',
    ft = { 'lua' },
    opts = {
      library = {
        { path = 'snacks.nvim', words = { 'Snacks' } },
        { path = '${3rd}/luv/library', words = { 'vim%.uv' } }, -- Load luvit types when the `vim.uv` word is found
      },
    },
  },

  -- sessions
  {
    'folke/persistence.nvim',
    event = 'BufReadPre', -- this will only start session saving when an actual file was opened
    opts = {
      -- add any custom options here
    },
    keys = {
      {
        '<leader>rs',
        function()
          require('persistence').load()
        end,
        desc = 'Restore Session',
      },
      {
        '<leader>ss',
        function()
          require('persistence').select()
        end,
        desc = 'Select Session',
      },
      {
        '<leader>ql',
        function()
          require('persistence').load({ last = true })
        end,
        desc = 'Restore Last Session',
      },
      {
        '<leader>qd',
        function()
          require('persistence').stop()
        end,
        desc = "Don't Save Current Session",
      },
    },
  },
}
