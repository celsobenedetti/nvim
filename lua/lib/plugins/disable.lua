-- disable these outright
local plugins = {
  'folke/noice.nvim',
  'akinsho/bufferline.nvim',
  'folke/persistence.nvim',
  'stevearc/dressing.nvim',
  'echasnovski/mini.pairs',
}

local M = {}

for _, plugin in ipairs(plugins) do
  vim.list_extend(M, { {
    plugin,
    enabled = false,
  } })
end

return M
