local enabled = true

-- Toggle cmp completion
return function()
  local cmp = require 'cmp'
  local augroupName = 'cmp-augroup'
  local toggle_completion = function(is_enabled)
    cmp.setup.buffer { enabled = is_enabled }
  end

  enabled = not enabled
  toggle_completion(enabled)

  if enabled then
    print 'Enabled completion (cmp)'
    vim.api.nvim_clear_autocmds { group = augroupName }
  else
    vim.api.nvim_create_autocmd('BufEnter', {
      desc = ('Disable completion: %s'):format 'BufEnter',
      group = vim.api.nvim_create_augroup(augroupName, { clear = true }),
      callback = function()
        toggle_completion(false)
      end,
    })
    print 'Disabled completion (cmp)'
  end
end
