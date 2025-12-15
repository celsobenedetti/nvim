local has_icons, devicons = pcall(require, 'nvim-web-devicons')

--- @return string
local function git_status()
  local status = vim.b.gitsigns_status_dict or {}
  local added = status.added or 0
  local modified = status.changed or 0
  local removed = status.removed or 0

  local result = ''
  if added > 0 or modified > 0 or removed > 0 then
    result = result .. ' '
  end

  if added > 0 then
    result = result .. ' %#GitSignsAdd# ' .. vim.g.icons.git.added .. added .. '%*'
  end
  if modified > 0 then
    result = result .. '%#GitSignsChange# ' .. vim.g.icons.git.modified .. modified .. '%*'
  end
  if removed > 0 then
    result = result .. '%#GitSignsDelete# ' .. vim.g.icons.git.deleted .. removed .. '%*'
  end
  return result
end

function _G.MyStatusLine()
  local relative_file = vim.fn.expand('%:.')

  local icon = ''
  if has_icons then
    icon = devicons.get_icon(relative_file) or ''
  end

  local branch = '  ' .. (vim.g.gitsigns_head or '')
  local file = icon .. ' ' .. relative_file
  local status = git_status()

  local left = branch .. status
  local middle = file

  return left .. '%=' .. middle .. '%=%='
end

vim.opt.statusline = '%!v:lua.MyStatusLine()'
