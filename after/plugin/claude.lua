local lib = {
  term = require('lib.term'),
}
vim.g.claude_bufnr = 0

local function is_claude_buf(buf)
  return buf > 0 and buf == vim.g.claude_bufnr and vim.api.nvim_buf_is_valid(buf) and not lib.term.is_toggle_term()
end

local function focus_buf(buf)
  local winid = vim.fn.bufwinid(buf)
  if winid ~= -1 then
    vim.api.nvim_set_current_win(winid)
  else
    vim.api.nvim_set_current_buf(buf)
  end
end

-- sticky claude terminal: focus existing claude buffer, or start a new one
local function claude()
  if is_claude_buf(vim.g.claude_bufnr) then
    focus_buf(vim.g.claude_bufnr)
    return
  end
  vim.cmd.term('claude')
  vim.g.claude_bufnr = vim.api.nvim_get_current_buf()
end

vim.api.nvim_create_autocmd('TermClose', {
  desc = 'claude: close terminal buffer when claude exits',
  callback = function(args)
    if args.buf ~= vim.g.claude_bufnr then
      return
    end
    vim.g.claude_bufnr = 0
    vim.schedule(function()
      if vim.api.nvim_buf_is_valid(args.buf) then
        vim.api.nvim_buf_delete(args.buf, { force = true })
      end
    end)
  end,
})

vim.api.nvim_create_user_command('Claude', claude, { desc = 'Open or focus the claude terminal' })

vim.keymap.set('n', '<leader>cl', '<cmd>Claude<CR>', { desc = 'claude: open/focus terminal' })
