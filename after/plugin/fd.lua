-- run fd with the given arguments and send results to the quickfix list

vim.api.nvim_create_user_command('Fd', function(opts)
  vim.system(vim.list_extend({ 'fd', '--hidden' }, opts.fargs), { text = true }, function(result)
    vim.schedule(function()
      if result.code ~= 0 then
        Snacks.notify.error(result.stderr or ('fd exited with code ' .. result.code), { title = 'Fd' })
        return
      end

      local files = vim.split(result.stdout or '', '\n', { trimempty = true })
      if #files == 0 then
        Snacks.notify.warn('no results', { title = 'Fd' })
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
