-- disable these outright
local plugins = {
  'folke/noice.nvim',
  'akinsho/bufferline.nvim',
  'stevearc/dressing.nvim',
  'nvim-mini/mini.pairs',
}

local M = {}

for _, plugin in ipairs(plugins) do
  vim.list_extend(M, { {
    plugin,
    enabled = false,
  } })
end

return M
