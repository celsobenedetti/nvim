-- use rg for native grep
-- and custom Grep command to grep and qflist
vim.opt.grepprg = 'rg --vimgrep --smart-case --hidden --ignore'
vim.opt.grepformat = '%f:%l:%c:%m'

local function do_grep(pattern, target)
  local cmd = 'silent grep ' .. vim.fn.fnameescape(pattern)
  if target then
    -- expand cmdline-special chars (% = current file, # = alternate, ~, <cword>, ...)
    -- so `:Grep query %` greps the current file. Only the target is expanded:
    -- expanding the pattern would mangle regex escapes (expandcmd('\b') -> <BS>).
    cmd = cmd .. ' ' .. vim.fn.fnameescape(vim.fn.expandcmd(target))
  end
  vim.cmd(cmd)
  vim.cmd.copen()
end

vim.api.nvim_create_user_command('Grep', function(opts)
  -- Split args into tokens on whitespace, honoring "..." and '...' quoting and
  -- backslash escapes (space, quote, backslash). Regex backslashes like `\b` are
  -- kept verbatim. This lets `:Grep "some query" file.txt` parse the quoted
  -- pattern as a single token, unlike a dumb split on spaces.
  local args = lib.strings.split_args(opts.args)
  if #args == 0 then
    vim.ui.input({ prompt = 'Grep: ' }, function(input)
      if input and input ~= '' then
        do_grep(input)
      end
    end)
    return
  end
  if #args > 2 then
    vim.notify('Usage: :Grep [pattern] [target]', vim.log.levels.WARN)
    return
  end
  if args[1] == '' then
    vim.notify('Grep: empty pattern', vim.log.levels.WARN)
    return
  end
  do_grep(args[1], args[2])
end, { nargs = '*', desc = 'rg grep; optional second arg scopes to a file or dir' })
