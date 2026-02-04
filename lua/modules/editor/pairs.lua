return {
  'windwp/nvim-autopairs',
  event = 'InsertEnter',
  config = function()
    require('nvim-autopairs').setup({
      -- Ignores word characters, %, ', [, ", ., `, and {
      ignored_next_char = [=[[%w%%%'%[%"%.%`%${]]=],
      -- BUG: adding this because of broken orgmode integration
      map_cr = false,
    })
  end,
}
