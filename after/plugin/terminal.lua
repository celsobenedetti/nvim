state.insert_when_entering_terminal = true

--- @module 'sticky terminal'
--- upsert terminal in current window (resume if available, create new otherwise)
local function sticky_terminal()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if
      lib.term.is_term(buf)
      and not lib.term.is_toggle_term(buf)
      and not lib.term.is_agent(buf)
      and lib.term.terminal_is_available(buf)
    then
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
    -- 'nowrap' + a non-zero 'sidescrolloff' horizontally scrolls the window to
    -- keep context around the cursor. Terminal-mode zeroes 'sidescrolloff'
    -- itself (the cursor is pinned to the terminal's own), but restores it on
    -- the way out: leaving the window parks the cursor at the end of the last
    -- line, nvim scrolls right to give it context, and a full-width TUI is
    -- drawn shifted left with blank columns at the right edge until the next
    -- resize. The terminal grid is exactly window-wide, so there is nothing
    -- off-screen to scroll to in the first place.
    vim.opt_local.sidescrolloff = 0
    vim.bo.filetype = 'terminal'
    lib.term.startinsert()
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

--- How deep under a terminal's job process to look for an agent. The sticky
--- agent terminals run `caveman <agent>`, whose job process is caveman's node
--- wrapper with the agent as its child; one level further also catches an
--- agent (or a `caveman <agent>`) launched by hand inside a shell terminal.
local AGENT_SEARCH_DEPTH = 2

--- Abort the quit nvim is in the middle of. ExitPre cannot refuse an exit by
--- returning, but nvim bails out of `:q`/`:qa` when the autocommand left the
--- window the quit started from invalid (before_quit_autocmds, ex_docmd.c), so
--- hand that window's buffer and screen space to a split and close it.
local function abort_quit()
  local quitting = vim.api.nvim_get_current_win()
  -- A window that refuses to split (too small, 'winfix*') leaves the quit
  -- unopposed; better that than closing the last window and exiting anyway.
  if not pcall(vim.cmd.split) then
    return
  end
  pcall(vim.api.nvim_win_close, quitting, true)
end

vim.api.nvim_create_autocmd('ExitPre', {
  desc = 'term: confirm the exit while an agent runs, then cleanup idle terminals',
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

    -- An agent session is long-lived and costs real work to lose, so ask before
    -- tearing anything down. This also fires for `:qa!`: ExitPre cannot see the
    -- bang, and one prompt on every exit path beats a silently killed agent.
    local running = {}
    for _, buf in ipairs(term_bufs) do
      local agent = lib.term.running_agent(buf, config.agents, AGENT_SEARCH_DEPTH)
      if agent and not vim.tbl_contains(running, agent) then
        table.insert(running, agent)
      end
    end
    -- Only an interactive session gets asked: with no UI attached confirm()
    -- blocks on stdin, so a headless nvim driving an agent terminal would hang
    -- on the way out instead of exiting.
    if #running > 0 and #vim.api.nvim_list_uis() > 0 then
      local msg = string.format('%s still running. Exit nvim?', table.concat(running, ', '))
      -- Esc/interrupt answers 0; treat anything but an explicit Yes as No.
      if vim.fn.confirm(msg, '&Yes\n&No', 2, 'Question') ~= 1 then
        abort_quit()
        return
      end
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
