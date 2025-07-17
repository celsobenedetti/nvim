return {
  {
    'ray-x/go.nvim',
    -- lock this in until merged:
    -- https://github.com/ray-x/go.nvim/pull/584
    commit = 'a3455f48cff718a86275115523dcc735535a13aa',
    dependencies = { -- optional packages
      'ray-x/guihua.lua',
      'neovim/nvim-lspconfig',
      'nvim-treesitter/nvim-treesitter',
    },
    config = function()
      require('go').setup()
    end,
    ft = { 'go', 'gomod' },
    build = ':lua require("go.install").update_all_sync()', -- if you need to install/update all binaries
  },
}
