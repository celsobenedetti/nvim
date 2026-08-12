vim.opt.grepprg = 'rg --vimgrep --smart-case --hidden --ignore'
vim.opt.grepformat = '%f:%l:%c:%m'

vim.api.nvim_create_user_command('Grep', function(opts)
  local pattern = opts.args
  if not pattern then
    vim.ui.input({ prompt = 'Grep: ' }, function(_pattern)
      pattern = _pattern
    end)
  end
  if not pattern then
    return
  end
  vim.cmd('silent grep ' .. vim.fn.fnameescape(pattern))
  vim.cmd.copen()
end, { nargs = '?' })
