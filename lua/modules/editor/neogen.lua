return {
  {
    lazy = true,
    'danymat/neogen',
    dependencies = 'nvim-treesitter/nvim-treesitter',
    opts = {
      snippet_engine = 'luasnip',
    },
    keys = {
      {
        '<leader>na',
        ':Neogen<CR>',
        desc = 'Neogen annotation',
      },
    },
  },
}
