return function()
  local status, orgmode = pcall(require, 'orgmode')
  if status then
    orgmode.action 'org_mappings.open_at_point'
  end
  vim.cmd 'ObsidianFollowLink'
end
