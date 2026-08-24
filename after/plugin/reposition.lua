-- Toggleable cursor repositioning modes. AutoZZ centers the cursor line on
-- every move; AutoZT keeps it at the top of the window. The modes are
-- mutually exclusive: enabling one disables the other.
local augroup = vim.api.nvim_create_augroup('celso_auto_reposition', { clear = true })

local active = nil --- @type 'zz'|'zt'|nil

--- Enables a mode, or disables the current one when mode is nil.
--- @param mode 'zz'|'zt'|nil
local function set_mode(mode)
  local prev = active
  active = mode
  vim.api.nvim_clear_autocmds({ group = augroup })
  if mode then
    vim.api.nvim_create_autocmd('CursorMoved', {
      group = augroup,
      callback = function()
        vim.cmd.norm(mode)
      end,
    })
  end
  Snacks.notify.info(string.format('auto %s: %s', mode or prev, mode ~= nil), { title = 'Reposition' })
end

local function toggle(mode)
  if active == mode then
    set_mode(nil)
  else
    set_mode(mode)
  end
end

vim.api.nvim_create_user_command('AutoZZ', function()
  toggle('zz')
end, { desc = 'Toggle auto zz mode (centers cursor on every move)' })

vim.api.nvim_create_user_command('AutoZT', function()
  toggle('zt')
end, { desc = 'Toggle auto zt mode (pins cursor line to window top on every move)' })
