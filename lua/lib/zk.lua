local M = {}

M.open_orgmode_or_obsidian_link = function()
  local status, orgmode = pcall(require, 'orgmode')
  if status then
    orgmode.action 'org_mappings.open_at_point'
  end
  vim.cmd 'ObsidianFollowLink'

  -- gf go to file
  -- TODO: figure something out instead of dumbly "gf"
  -- vim.api.nvim_feedkeys(Keys 'gf', 'n', true)
end

return M
