local performance_mode = vim.g.performance

if not performance_mode then
  return {}
end

-- disable non critical plugins
local plugins = {
  'folke/noice.nvim',
  'sphamba/smear-cursor.nvim',
  'Bekaboo/dropbar.nvim',
  'akinsho/bufferline.nvim',
  'mbbill/undotree',
  'akinsho/git-conflict.nvim',
  'folke/todo-comments.nvim',
  'rafamadriz/friendly-snippets',
  'echasnovski/mini.hipatterns',
  'nvim-lualine/lualine.nvim',
  'folke/persistence.nvim',
  'chrisgrieser/nvim-origami',
  'rachartier/tiny-inline-diagnostic.nvim',
  'stevearc/dressing.nvim',
  'wakatime/vim-wakatime',
}

local M = {}

for _, plugin in ipairs(plugins) do
  vim.list_extend(M, { {
    plugin,
    enabled = not performance_mode,
  } })
end

return M
