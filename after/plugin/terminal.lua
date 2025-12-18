---@module "terminal" home cooked terminal management plugin
---@author Celso Benedetti
---
--- fuzzy search for open terminal buffers
--- if found, open it
--- else create new terminal with name equal to query

---@param name string
local create_terminal_buffer = function(name)
  vim.cmd('term')
  vim.schedule(function()
    vim.cmd('file ' .. vim.fn.fnameescape(name))
  end)
end

map('n', '<C-t>', function()
  local picker = Snacks.picker.buffers({
    prompt = 'search/create terminal: ',
    filter = {
      filter = function(item)
        return item.buftype == 'terminal'
      end,
    },
    confirm = function(picker)
      local item = picker:current()
      if item then
        return vim.cmd('b ' .. item.buf)
      else
        local pattern = picker.finder.filter.pattern or ''
        local name = pattern ~= '' and pattern or 'Terminal'
        picker:close()
        vim.schedule(function()
          create_terminal_buffer(name)
        end)
      end
    end,
  })

  if picker.finder:count() == 0 then
    vim.ui.input({ prompt = 'Create terminal:' }, function(input)
      if input and #input > 0 then
        create_terminal_buffer(input)
      end
    end)
  end
end, { desc = 'search or create terminal' })

-- disable line numbers for terminal buffers
vim.api.nvim_create_autocmd('TermEnter', {
  group = vim.api.nvim_create_augroup('terminal-enter', { clear = true }),
  callback = function()
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
  end,
})
