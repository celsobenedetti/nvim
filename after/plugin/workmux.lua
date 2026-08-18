--- send the current buffer's path to a running workmux agent.
--- Falls back to a picker when multiple live agents are in the repo.
local lib = lib

--- Path of the current buffer, relative to the agent's workdir when the file
--- shares the same git repo as the agent, else absolute. Returns nil when no
--- file.
---@param agent? {workdir:string}
local function path_for_agent(agent)
  local file = vim.fn.expand('%:p')
  if file == '' then
    return nil
  end
  if agent and agent.workdir then
    local file_root = lib.tmux.git_toplevel(file)
    local agent_root = lib.tmux.git_toplevel(agent.workdir)
    if file_root and agent_root and file_root == agent_root then
      local prefix = agent.workdir:gsub('/$', '')
      if file:sub(1, #prefix + 1) == prefix .. '/' then
        return file:sub(#prefix + 1):gsub('^/+', '')
      end
    end
  end
  return file
end

local function range_for_agent(agent)
  local start_line = vim.fn.line('v')
  local end_line = vim.fn.line('.')
  if start_line > end_line then
    start_line, end_line = end_line, start_line
  end
  local path = path_for_agent(agent)
  if not path then
    return nil
  end
  return { path = path, start_line = start_line, end_line = end_line }
end

local function send(agent, text)
  local ok = lib.tmux.workmux_send(agent.handle, text)
  if not ok then
    Snacks.notify.error(string.format('Failed to send to %s', agent.handle), { title = 'workmux' })
  end
end

--- Project name for an agent: the parent of its worktree root with the
--- `__worktrees` suffix stripped (e.g. `.../nvim__worktrees/foo` -> `nvim`).
---@param agent {workdir:string}
local function project_name(agent)
  local parent = vim.fn.fnamemodify(agent.workdir, ':h:h:t')
  parent = parent:gsub('__worktrees$', '')
  if parent == '' then
    return agent.workdir
  end
  return parent
end

--- Pick a single agent, or nil when none/ambiguous. When multiple agents,
--- opens an fzf picker and sends `build(agent)` to the chosen one.
---@param agents table[]
---@param build fun(agent: table): string?
local function choose_agent(agents, build)
  if #agents == 1 then
    send(agents[1], build(agents[1]))
    return agents[1]
  end

  if #agents == 0 then
    Snacks.notify.info('No running agents', { title = 'workmux' })
    return nil
  end

  local entries = {}
  local by_handle = {}
  for _, agent in ipairs(agents) do
    local display = string.format(
      '%s\t%s | %s | %s | %s',
      agent.handle,
      project_name(agent),
      agent.agent_kind,
      agent.status,
      agent.title or ''
    )
    entries[#entries + 1] = display
    by_handle[agent.handle] = agent
  end

  require('fzf-lua').fzf_exec(entries, {
    prompt = 'Agent> ',
    fzf_opts = {
      ['--delimiter'] = '[\t]',
      ['--with-nth'] = '2..', -- hide handle from fuzzy match list, keep it as hidden field
    },
    winopts = { title = 'Select agent' },
    actions = {
      ['default'] = function(selected)
        if selected and selected[1] then
          local handle = vim.split(selected[1], '\t')[1]
          local agent = by_handle[handle]
          if agent then
            send(agent, build(agent))
          end
        end
      end,
    },
  })
  return nil
end

--- send current buffer path to agent
local function send_current_buffer()
  if not lib.tmux.active() then
    Snacks.notify.warn('Agent actions require tmux', { title = 'workmux' })
    return
  end

  local file = vim.fn.expand('%:p')
  if file == '' then
    Snacks.notify.info('No file in buffer', { title = 'workmux' })
    return
  end

  local agents = lib.tmux.workmux_agents()
  if #agents == 0 then
    Snacks.notify.info('No running agents', { title = 'workmux' })
    return
  end
  if #agents > 1 then
    choose_agent(agents, function(agent)
      return path_for_agent(agent)
    end)
    return
  end

  local agent = agents[1]
  local text = path_for_agent(agent)
  if not text then
    Snacks.notify.info('No file in buffer', { title = 'workmux' })
    return
  end
  send(agent, text)
end

--- send visual selection (path:start:end + selected text) to agent
local function send_visual_range()
  if not lib.tmux.active() then
    Snacks.notify.warn('Agent actions require tmux', { title = 'workmux' })
    return
  end

  local agents = lib.tmux.workmux_agents()
  if #agents == 0 then
    Snacks.notify.info('No running agents', { title = 'workmux' })
    return
  end
  if #agents > 1 then
    choose_agent(agents, function(agent)
      local range = range_for_agent(agent)
      if not range then
        return nil
      end
      local lines = vim.api.nvim_buf_get_lines(0, range.start_line - 1, range.end_line, false)
      local selected = table.concat(lines, '\n')
      return string.format('%s:%d:%d\n%s', range.path, range.start_line, range.end_line, selected)
    end)
    return
  end

  local agent = agents[1]
  local range = range_for_agent(agent)
  if not range then
    Snacks.notify.info('No file in buffer', { title = 'workmux' })
    return
  end

  local lines = vim.api.nvim_buf_get_lines(0, range.start_line - 1, range.end_line, false)
  local selected = table.concat(lines, '\n')
  local text = string.format('%s:%d:%d\n%s', range.path, range.start_line, range.end_line, selected)
  send(agent, text)
end

-- keymaps
vim.keymap.set('n', 'gA', send_current_buffer, { desc = 'workmux: send current buffer' })
vim.keymap.set('v', 'gY', send_visual_range, { desc = 'workmux: send visual range' })
