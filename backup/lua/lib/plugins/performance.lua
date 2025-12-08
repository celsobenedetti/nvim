if not vim.g.performance then
  return {}
end

-- disable non critical plugins
local plugins = {
  'folke/noice.nvim',
  'Bekaboo/dropbar.nvim',
  'akinsho/bufferline.nvim',
  'nvim-mini/mini.hipatterns',
  'folke/persistence.nvim',
  'stevearc/dressing.nvim',

  -- nice to haves
  'nvim-lualine/lualine.nvim',
  'folke/todo-comments.nvim',
  'sphamba/smear-cursor.nvim',
  'akinsho/git-conflict.nvim',
  'rafamadriz/friendly-snippets',
  'chrisgrieser/nvim-origami',
  'rachartier/tiny-inline-diagnostic.nvim',
  'wakatime/vim-wakatime',
}

local M = {}

for _, plugin in ipairs(plugins) do
  vim.list_extend(M, { {
    plugin,
    enabled = false,
  } })
end

return M
