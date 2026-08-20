state.insert_when_entering_terminal = true

--- @module 'sticky terminal'
--- upsert terminal in current window (resume if available, create new otherwise)
local function sticky_terminal()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if lib.term.is_term(buf) and not lib.term.is_toggle_term(buf) and lib.term.terminal_is_available(buf) then
      vim.api.nvim_set_current_buf(buf)
      return
    end
  end
  vim.cmd.term()
end
vim.keymap.set('n', '<leader>te', sticky_terminal, { desc = 'terminal: sticky terminal' })

--- @module 'toggle terminal'
--- references:
---     https://github.com/kristijanhusak/neovim-config/commit/5f8da622f6668ba3744b33facfa88bd48a6e56a4#diff-4a7625707401ac0489aab5c8a5daca2adb4ef8de341c8d523d93e6c507fc58d4
state.toggle_term_bufnr = -1
local function toggle_terminal()
  local target_height = math.max(20, math.floor(vim.fn.winheight(0) * 0.5))
  if state.toggle_term_bufnr < 0 then
    vim.cmd('botright sp | term')
    vim.cmd.resize(target_height)
    vim.cmd.setlocal('bufhidden=hide')
    state.toggle_term_bufnr = vim.api.nvim_get_current_buf()
    return
  end

  local winnr = vim.fn.bufwinnr(state.toggle_term_bufnr)
  if winnr > -1 then
    vim.api.nvim_win_close(vim.fn.win_getid(winnr), true)
    return
  end
  if not vim.api.nvim_buf_is_valid(state.toggle_term_bufnr) then
    state.toggle_term_bufnr = -1
    return
  end
  vim.cmd('botright sp | b' .. state.toggle_term_bufnr)
  vim.cmd.resize(target_height)
end
vim.keymap.set({ 'n', 't' }, config.keys['<C-/>'], toggle_terminal, { desc = 'Toggle terminal' })

--- @module 'terminal autocmds'
-- stylua: ignore start
local augroup = vim.api.nvim_create_augroup('custom-term', {})
-- insert mode when entering terminal window
vim.api.nvim_create_autocmd('BufWinEnter',
  {
    desc = 'terminal: insert mode when entering terminal window',
    pattern = 'term://*',
    group = augroup,
    callback = lib.term.startinsert,
  })
vim.api.nvim_create_autocmd('WinEnter',
  {
    desc = 'terminal: insert mode when entering terminal window',
    pattern = 'term://*',
    group = augroup,
    callback = lib.term.startinsert,
  })
-- stylua: ignore end

vim.api.nvim_create_autocmd('TermOpen', {
  desc = 'term: TermOpen init function',
  group = augroup,
  callback = function()
    vim.opt_local.number = false
    vim.opt_local.scrolloff = 0
    vim.bo.filetype = 'terminal'
    vim.schedule(lib.term.startinsert)
  end,
})

vim.api.nvim_create_autocmd('TermClose', {
  desc = 'term: TermClose cleanup',
  callback = function()
    local bufs = lib.buffers.get_valid_bufs()
    for _, buf in ipairs(bufs) do
      if buf == state.toggle_term_bufnr then -- float term still open
        return
      end
    end
    state.toggle_term_bufnr = -1
  end,
  group = augroup,
})

-- --- @module 'terminal follow: tail output in unfocused windows'
-- --- Neovim only keeps an unfocused terminal window scrolled to the newest output
-- --- while that window's cursor sits exactly on the last buffer line
-- --- (adjust_topline_cursor in terminal.c). TUIs like pi park their cursor a few
-- --- lines above the end (input box), so the built-in tailing never engages after
-- --- leaving the window. Remember whether the window was following when the user
-- --- left; on new output, pin its cursor back to the end.
-- local following_windows = {} -- winid -> boolean
--
-- -- Coalesce per-buffer scroll work: on_lines fires per changed_lines call, which
-- -- the terminal refresh path emits per scrollback line. Schedule once per event-
-- -- loop batch instead of running on every callback.
-- local pending_follow = {} -- buf -> true
--
-- local function follow_terminal_output(buf)
--   if pending_follow[buf] then
--     return
--   end
--   pending_follow[buf] = true
--   vim.schedule(function()
--     pending_follow[buf] = nil
--     local line_count = vim.api.nvim_buf_line_count(buf)
--     local current_win = vim.api.nvim_get_current_win()
--     for _, win in ipairs(vim.api.nvim_list_wins()) do
--       if
--         win ~= current_win
--         and vim.api.nvim_win_get_buf(win) == buf
--         and following_windows[win]
--         -- built-in follow already keeps a caught-up window at the end
--         and vim.api.nvim_win_get_cursor(win)[1] < line_count
--       then
--         vim.api.nvim_win_set_cursor(win, { line_count, 0 })
--       end
--     end
--   end)
-- end
--
-- vim.api.nvim_create_autocmd('WinLeave', {
--   desc = 'term: remember whether the terminal window was tailing output',
--   group = augroup,
--   callback = function()
--     local win = vim.api.nvim_get_current_win()
--     local buf = vim.api.nvim_win_get_buf(win)
--     if vim.bo[buf].buftype ~= 'terminal' then
--       return
--     end
--     local cursor = vim.api.nvim_win_get_cursor(win)
--     following_windows[win] = lib.term.was_following(cursor[1], vim.api.nvim_buf_line_count(buf), vim.fn.mode())
--   end,
-- })
--
-- vim.api.nvim_create_autocmd('TermOpen', {
--   desc = 'term: tail new output in unfocused windows showing this terminal',
--   group = augroup,
--   callback = function()
--     local buf = vim.api.nvim_get_current_buf()
--     if vim.b[buf].term_follow_attached then
--       return
--     end
--     vim.b[buf].term_follow_attached = true
--     vim.api.nvim_buf_attach(buf, false, {
--       on_lines = function()
--         follow_terminal_output(buf)
--       end,
--     })
--   end,
-- })

vim.api.nvim_create_autocmd('ExitPre', {
  desc = 'term: cleanup idle terminal when exiting neovim',
  callback = function()
    local term_bufs = {}
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_get_option_value('buftype', { buf = buf }) == 'terminal' then
        table.insert(term_bufs, buf)
      end
    end
    if #term_bufs == 0 then
      return
    end

    local busy_terms = {}
    for _, buf in ipairs(term_bufs) do
      if lib.term.terminal_is_available(buf) then
        vim.api.nvim_buf_delete(buf, { force = true })
      else
        table.insert(busy_terms, buf)
      end
    end

    if #busy_terms > 0 then
      local msg = string.format(
        'there %s %d busy terminal%s',
        #busy_terms > 1 and 'are' or 'is',
        #busy_terms,
        #busy_terms > 1 and 's' or ''
      )
      Snacks.notify.warn(msg, { title = 'Running commands', icon = '', style = 'fancy' })
      vim.cmd.buffer(busy_terms[1])
    end
  end,
})
