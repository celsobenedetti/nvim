local enabled = false
local augroup = vim.api.nvim_create_augroup('celso_auto_zz', { clear = true })

local function enable()
  enabled = true
  vim.api.nvim_create_autocmd('CursorMoved', {
    group = augroup,
    callback = function()
      vim.cmd.norm('zz')
    end,
  })
end

local function disable()
  enabled = false
  vim.api.nvim_clear_autocmds({ group = augroup })
end

vim.api.nvim_create_user_command('AutoZZ', function()
  if enabled then
    disable()
  else
    enable()
  end
  Snacks.notify.info(string.format('auto zz: %q', enabled), { title = 'AutoZZ' })
end, { desc = 'Toggle auto zz mode (centers cursor on every move)' })
