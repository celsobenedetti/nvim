--- send the current buffer's path to a running workmux agent.
--- Falls back to a picker when multiple live agents are in the repo.
local lib = lib

--- Parse `workmux status --json` into a list of all live agents, regardless
--- of repository. Each agent carries its worktree path (workdir), used to
--- decide relative-vs-absolute path resolution, and its tmux pane_id.
---@return {handle:string, branch:string, status:string, title:string, workdir:string, agent_kind:string, pane_id:string}[]
local function workmux_agents()
  if not lib.tmux.active() then
    return {}
  end

  local output = vim.fn.system({ 'workmux', 'status', '--json' })
  if vim.v.shell_error ~= 0 then
    return {}
  end

  local ok, data = pcall(vim.json.decode, output)
  if not ok or not data or not data.agents then
    return {}
  end

  local agents = {}
  for _, agent in ipairs(data.agents) do
    table.insert(agents, {
      session = agent.session,
      handle = agent.worktree,
      branch = agent.branch,
      status = agent.status,
      title = agent.title,
      workdir = agent.workdir,
      agent_kind = agent.agent_kind,
      pane_id = agent.pane_id,
    })
  end
  return agents
end

--- Resolve the canonical git toplevel of a path (realpath of
--- `rev-parse --show-toplevel`). Cached per path to avoid repeated subprocess
--- spawns when enumerating agents. `path` may be a file or directory.
---@param path string
---@return string?
local cache = {}
local function git_toplevel(path)
  if cache[path] then
    return cache[path]
  end
  local dir = vim.fn.isdirectory(path) == 1 and path or vim.fn.fnamemodify(path, ':h')
  local out = vim.fn.system({ 'git', '-C', dir, 'rev-parse', '--show-toplevel' })
  if vim.v.shell_error ~= 0 then
    cache[path] = false
    return nil
  end
  local resolved = vim.trim(out):gsub('%s+$', '')
  cache[path] = resolved
  return resolved
end

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
    local file_root = git_toplevel(file)
    local agent_root = git_toplevel(agent.workdir)
    if file_root and agent_root and file_root == agent_root then
      local prefix = agent.workdir:gsub('/$', '')
      if file:sub(1, #prefix + 1) == prefix .. '/' then
        return file:sub(#prefix + 1):gsub('^/+', '')
      end
    end
  end
  return file
end

--- Selected text for the current visual selection via lib.visual.
local function visual_selection()
  local start_line, end_line = lib.visual.get_region()
  if not start_line or not end_line then
    return nil
  end
  local selected = lib.visual.get_selection()
  if not selected then
    return nil
  end
  return { start_line = start_line, end_line = end_line, selected = selected }
end

local function send(agent, text)
  local ok = lib.tmux.send_to_pane(agent.pane_id, text)
  if not ok then
    Snacks.notify.error(string.format('Failed to send to %s', agent.handle), { title = 'workmux' })
    return
  end
  lib.tmux.focus_pane(agent.pane_id)
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

  local rows = {}
  local by_handle = {}
  for _, agent in ipairs(agents) do
    table.insert(rows, {
      agent.session or '',
      agent.agent_kind or '',
      agent.status or '',
      agent.title or '',
    })
    by_handle[agent.handle] = agent
  end

  -- pad every column (except the last) to its max width so the ` | `
  -- separators line up into aligned table columns
  local widths = { 0, 0, 0 }
  for _, row in ipairs(rows) do
    for i = 1, 3 do
      widths[i] = math.max(widths[i], vim.fn.strdisplaywidth(row[i]))
    end
  end

  local entries = {}
  for i, row in ipairs(rows) do
    local padded = {}
    for c = 1, 3 do
      padded[c] = row[c] .. string.rep(' ', widths[c] - vim.fn.strdisplaywidth(row[c]))
    end
    local display = string.format('%s\t%s | %s | %s | %s', agents[i].handle, padded[1], padded[2], padded[3], row[4])
    entries[#entries + 1] = display
  end

  require('fzf-lua').fzf_exec(entries, {
    prompt = 'Agent> ',
    fzf_opts = {
      ['--delimiter'] = '[\t]',
      ['--with-nth'] = '2..', -- hide handle from fuzzy match list, keep it as hidden field
    },
    winopts = {
      title = 'Select agent',
      row = 0.96, -- bottom edge
      col = 0, -- left edge
      width = 1,
      height = 0.3,
      preview = { hidden = true },
    },
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
local function send_current_filepath()
  if not lib.tmux.active() then
    Snacks.notify.warn('Agent actions require tmux', { title = 'workmux' })
    return
  end

  local file = vim.fn.expand('%:p')
  if file == '' then
    Snacks.notify.info('No file in buffer', { title = 'workmux' })
    return
  end

  local agents = workmux_agents()
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
  send(agent, ' ' .. text .. ' ')
end

--- send visual selection (path:start:end + selected text) to agent
local function send_visual_range()
  if not lib.tmux.active() then
    Snacks.notify.warn('Agent actions require tmux', { title = 'workmux' })
    return
  end

  local agents = workmux_agents()
  if #agents == 0 then
    Snacks.notify.info('No running agents', { title = 'workmux' })
    return
  end
  local sel = visual_selection()
  if not sel then
    return
  end

  if #agents > 1 then
    choose_agent(agents, function(agent)
      local path = path_for_agent(agent)
      if not path then
        return nil
      end
      return string.format(' %s:%d:%d\n ```\n%s\n```', path, sel.start_line, sel.end_line, sel.selected)
    end)
    return
  end

  local agent = agents[1]
  local path = path_for_agent(agent)
  if not path then
    Snacks.notify.info('No file in buffer', { title = 'workmux' })
    return
  end
  local text = string.format('%s:%d:%d\n```\n%s\n```', path, sel.start_line, sel.end_line, sel.selected)
  send(agent, text)
end

-- keymaps
-- vim.keymap.set('n', 'gA', send_current_filepath, { desc = 'workmux: send current buffer' })
vim.keymap.set('v', 'gY', send_visual_range, { desc = 'workmux: send visual range' })
