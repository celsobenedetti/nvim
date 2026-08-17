_G.get_statuscolumn = function()
  return package.loaded.snacks and require('snacks.statuscolumn').get() or ''
end

vim.opt.statuscolumn = [[%!v:lua.get_statuscolumn()]]
