return {
  'windwp/nvim-autopairs',
  event = 'InsertEnter',
  config = function()
    require('nvim-autopairs').setup({
      -- BUG: adding this because of broken orgmode integration
      map_cr = false,
    })
  end,
}
