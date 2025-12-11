---@module base module with general required plugins

return {
  -- core plugins
  { 'wakatime/vim-wakatime' }, -- code time tracking goodness
  { 'neovim/nvim-lspconfig' }, -- install lspconfig through lazy.nvim

  -- json/yaml schema store
  { 'b0o/SchemaStore.nvim', lazy = true, ft = { 'json', 'yaml', 'toml' } },

  -- lua lsp intellisense for neovim config
  {
    'folke/lazydev.nvim',
    ft = { 'lua' },
    opts = {
      library = {
        { path = 'snacks.nvim', words = { 'Snacks' } },
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
      },
    },
  },
}
