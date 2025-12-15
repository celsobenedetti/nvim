local cwd = require('lib.cwd')
local has_icons, devicons = pcall(require, 'nvim-web-devicons')

function _G.MyStatusLine()
  local branch = ''

  if cwd.is_git_repo() then
    branch = '  ' .. vim.trim(vim.fn.system('git branch --show-current'))
  end

  local relative_file = vim.fn.expand('%:.')

  local icon = ''
  if has_icons then
    icon = devicons.get_icon(relative_file) or ''
  end

  return branch .. '%=' .. icon .. ' ' .. relative_file .. '%=%='
end

vim.opt.statusline = '%!v:lua.MyStatusLine()'
