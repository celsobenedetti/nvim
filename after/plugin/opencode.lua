vim.g.opencode_bufnr = 0

local function is_opencode_buf(buf)
  return buf > 0 and buf == vim.g.opencode_bufnr and vim.api.nvim_buf_is_valid(buf)
end

local function focus_buf(buf)
  local winid = vim.fn.bufwinid(buf)
  if winid ~= -1 then
    vim.api.nvim_set_current_win(winid)
  else
    vim.api.nvim_set_current_buf(buf)
  end
end

-- sticky opencode terminal: focus existing opencode buffer, or start a new one
local function opencode()
  if is_opencode_buf(vim.g.opencode_bufnr) then
    focus_buf(vim.g.opencode_bufnr)
    return
  end
  vim.cmd.term('opencode')
  vim.g.opencode_bufnr = vim.api.nvim_get_current_buf()
end

vim.api.nvim_create_autocmd('TermClose', {
  desc = 'opencode: close terminal buffer when opencode exits',
  callback = function(args)
    if args.buf ~= vim.g.opencode_bufnr then
      return
    end
    vim.g.opencode_bufnr = 0
    vim.schedule(function()
      if vim.api.nvim_buf_is_valid(args.buf) then
        vim.api.nvim_buf_delete(args.buf, { force = true })
      end
    end)
  end,
})

vim.api.nvim_create_user_command('Opencode', opencode, { desc = 'Open or focus the opencode terminal' })

vim.keymap.set('n', '<leader>oC', '<cmd>Opencode<CR>', { desc = 'opencode: open/focus terminal' })
