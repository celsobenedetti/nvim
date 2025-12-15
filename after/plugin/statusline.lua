local has_icons, devicons = pcall(require, 'nvim-web-devicons')

function _G.MyStatusLine()
  local relative_file = vim.fn.expand('%:.')

  local icon = ''
  if has_icons then
    icon = devicons.get_icon(relative_file) or ''
  end

  local branch = vim.g.gitsigns_head or ''
  return '  ' .. branch .. '%=' .. icon .. ' ' .. relative_file .. '%=%='
end

vim.opt.statusline = '%!v:lua.MyStatusLine()'
