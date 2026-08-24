-- run fd with the given arguments and send results to the quickfix list

vim.api.nvim_create_user_command('Fd', function(opts)
  local fd = { 'fd', '--hidden' }
  -- split config into newline-separated lines, then each line into argv words
  -- ("--exclude .git" must be two args or fd rejects it)
  for _, line in ipairs(lib.strings.split(config.cmd.fd.ignore, '\n')) do
    vim.list_extend(fd, lib.strings.split_args(line))
  end
  fd = vim.list_extend(fd, opts.fargs)

  vim.system(fd, { text = true }, function(result)
    vim.schedule(function()
      if result.code ~= 0 then
        Snacks.notify.error(result.stderr or ('fd exited with code ' .. result.code), { title = 'Fd' })
        return
      end

      local files = vim.split(result.stdout or '', '\n', { trimempty = true })
      if #files == 0 then
        Snacks.notify.warn('no results', { title = 'Fd' })
        vim.cmd.cclose()
        return
      end

      if #files == 1 then
        vim.cmd.edit(vim.fn.fnameescape(files[1]))
        vim.cmd.cclose()
        return
      end

      local items = {}
      for _, file in ipairs(files) do
        table.insert(items, { filename = file })
      end

      vim.fn.setqflist({}, ' ', { title = 'Fd ' .. opts.args, items = items })
      vim.cmd.copen()
    end)
  end)
end, { nargs = '*', complete = 'file', desc = 'Run fd and send results to the quickfix list' })
