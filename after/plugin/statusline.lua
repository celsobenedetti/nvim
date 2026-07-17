---@module 'statusline' home cooked statusline plugin
---@author Celso Benedetti
---
--- example:
---  main  󰢱 after/plugin/statusline.lua +3 ~1 -1   5  1  1                                                       stylua   lua_ls
---
--- try to cache as much as possible since the statusline is re-rendered on every keystroke
---
---
---
local has_icons, devicons = pcall(require, 'nvim-web-devicons')
local strings = require('lib.strings')
local hl = strings.hl
local LEFT_SEPARATOR = hl(vim.g.hl.text.secondary, vim.g.icons.separator.right)
local RIGHT_SEPARATOR = hl(vim.g.hl.text.secondary, vim.g.icons.separator.left)
local LEFT_PREFIX = ' ' -- os.getenv('TMUX') and LEFT_SEPARATOR or ' '
local RIGHT_SUFFIX = ' ' -- #right > 0 and RIGHT_SEPARATOR or ''

local modules = {
  _git_branch = function()
    if not vim.g.gitsigns_head or #vim.g.gitsigns_head == 0 then
      return ''
    end

    return hl(vim.g.hl.text.highlight, vim.g.icons.git.branch)
      .. hl(vim.g.hl.text.secondary, (vim.g.gitsigns_head or ''))
  end,

  _branch_sync_status = function()
    local branch_status = ''
    if vim.g.branch_commits_behind_origin and vim.g.branch_commits_behind_origin > 0 then
      branch_status = ' ' .. vim.g.icons.git.behind .. vim.g.branch_commits_behind_origin
    end
    if vim.g.branch_commits_ahead_of_origin and vim.g.branch_commits_ahead_of_origin > 0 then
      branch_status = branch_status .. vim.g.icons.git.ahead .. vim.g.branch_commits_ahead_of_origin
    end

    if #branch_status == 0 then
      return ''
    end
    return hl(vim.g.hl.text.secondary, branch_status)
  end,

  _file = function()
    if not vim.g.statusline_show_filepath then
      return ''
    end
    vim.b.relative_file = vim.fn.expand('%:.')
    local icon = ''
    if has_icons then
      local ft_icon, ft_color = devicons.get_icon(vim.b.relative_file)
      if ft_icon then
        icon = hl(ft_color, ft_icon) .. ' '
      end
    end

    local file = hl(vim.g.hl.text.secondary, vim.b.relative_file)
    return icon .. '' .. file
  end,

  _git_status = function()
    local status = vim.b.gitsigns_status_dict or {}
    local added = status.added or 0
    local modified = status.changed or 0
    local removed = status.removed or 0

    if added == 0 and modified == 0 and removed == 0 then
      return ''
    end

    local result = ''
    if added > 0 then
      result = result .. hl('GitSignsAdd', vim.g.icons.git.added .. added)
    end
    if modified > 0 then
      --
      result = result .. hl('GitSignsChange', vim.g.icons.git.modified .. modified)
    end
    if removed > 0 then
      result = result .. hl('GitSignsDelete', vim.g.icons.git.removed .. removed)
    end
    return result
    -- LSP clients attached to buffer
  end,

  _lsps = function()
    local bufnr = vim.api.nvim_get_current_buf()
    local clients = vim.lsp.get_clients({ bufnr = bufnr })
    if next(clients) == nil then
      return ''
    end

    local c = {}
    for _, client in pairs(clients) do
      table.insert(c, client.name)
    end
    return hl(vim.g.hl.text.highlight, vim.g.icons.lsp)
      .. hl(vim.g.hl.text.secondary, table.concat(vim.fn.reverse(c), ', '))
  end,

  _formatters = function()
    local ok, conform = pcall(require, 'conform')
    if not ok then
      return ''
    end

    local bufnr = vim.api.nvim_get_current_buf()
    local formatters = conform.list_formatters_for_buffer(bufnr)
    local c = {}
    for _, formatter in pairs(formatters) do
      table.insert(c, formatter)
    end
    local result = table.concat(c, ', ')
    if #result == 0 then
      return ''
    end

    return hl(vim.g.hl.text.highlight, vim.g.icons.format) .. hl(vim.g.hl.text.secondary, result)
  end,

  _diagnostics = function(bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    local count = { 0, 0, 0, 0 } -- error, warn, info, hint
    for _, diagnostic in pairs(vim.diagnostic.get(bufnr)) do
      count[diagnostic.severity] = count[diagnostic.severity] + 1
    end
    local result = ''
  -- stylua: ignore start
  if count[1] > 0 then result = result .. hl('DiagnosticError', vim.g.icons.diagnostics.error .. tostring(count[1]) .. ' ') end
  if count[2] > 0 then result = result .. hl('DiagnosticWarn', vim.g.icons.diagnostics.warn .. tostring(count[2]) .. ' ') end
  if count[3] > 0 then result = result .. hl('DiagnosticInfo', vim.g.icons.diagnostics.info .. tostring(count[3]) .. ' ') end
  if count[4] > 0 then result = result .. hl('DiagnosticHint', vim.g.icons.diagnostics.hint .. tostring(count[4]) .. ' ') end
    -- stylua: ignore end
    return result
  end,

  _macro = function()
    if not vim.g.recording_macro then
      return ''
    end
    return hl(vim.g.hl.warn, '  recording macro ')
  end,

  _terminal = function()
    if not vim.b.term then
      return ''
    end
    return hl(vim.g.hl.highlight, '   terminal ')
  end,

  _location = function()
    if not vim.g.statusline_show_position then
      return ''
    end
    return hl(vim.g.hl.text.subtext, '%l:%v')
  end,

  _time = function()
    return os.date('%H:%M')
  end,

  _search_results = function()
    if vim.v.hlsearch == 1 then
      local sinfo = vim.fn.searchcount({ maxcount = 0 })
      local search_stat = sinfo.incomplete > 0 and '[?/?]'
        or sinfo.total > 0 and ('[%s/%s]'):format(sinfo.current, sinfo.total)
        or nil

      if search_stat then
        return hl(vim.g.hl.text.subtext, search_stat)
      end
    end
  end,
}

local function setup_caching_and_updating()
  -- Cache LSP clients on attach/detach
  vim.api.nvim_create_autocmd({ 'LspAttach', 'LspDetach' }, {
    callback = function(args)
      local bufnr = args.buf
      vim.api.nvim_buf_set_var(bufnr, 'cached_lsps', modules._lsps())
    end,
  })

  -- Cache formatters and file on buffer enter
  vim.api.nvim_create_autocmd('BufEnter', {
    callback = function()
      local bufnr = vim.api.nvim_get_current_buf()
      vim.api.nvim_buf_set_var(bufnr, 'cached_formatters', modules._formatters())
      vim.api.nvim_buf_set_var(bufnr, 'cached_file', modules._file())
    end,
  })

  -- Cache diagnostics when LSP publishes them (async-safe, for any buffer)
  vim.api.nvim_create_autocmd('DiagnosticChanged', {
    callback = function(args)
      vim.api.nvim_buf_set_var(args.buf, 'cached_diagnostics', modules._diagnostics(args.buf))
    end,
  })

  -- Cache diagnostics, git status on UI/input events (fallback)
  vim.api.nvim_create_autocmd({ 'TextChanged', 'InsertLeave', 'WinEnter', 'BufWritePost' }, {
    callback = function()
      local bufnr = vim.api.nvim_get_current_buf()
      vim.defer_fn(function()
        pcall(function()
          vim.api.nvim_buf_set_var(bufnr, 'cached_diagnostics', modules._diagnostics())
          vim.api.nvim_buf_set_var(bufnr, 'cached_git_status', modules._git_status())
        end)
      end, 100)
    end,
  })

  -- Async, throttled branch status updates (avoid blocking UI with system())
  local function async_git_count(cmd, cb)
    vim.system({ 'bash', '-lc', cmd }, { text = true }, function(res)
      local n = tonumber((res.stdout or ''):match('%d+')) or 0
      vim.schedule(function()
        pcall(cb, n)
      end)
    end)
  end

  local _updating = false
  local last_run = 0
  local function update_branch_status()
    if _updating then
      return
    end
    _updating = true
    async_git_count(vim.g.cmd.git.commits_ahead_of_origin, function(n)
      vim.g.branch_commits_ahead_of_origin = n
    end)
    async_git_count(vim.g.cmd.git.commits_behind_origin, function(n)
      vim.g.branch_commits_behind_origin = n
      _updating = false
    end)
  end

  local function maybe_update_branch_status()
    local now = (vim.uv or vim.loop).now()
    if now - last_run < 60000 then -- throttle to once per minute
      return
    end
    last_run = now
    update_branch_status()
  end

  vim.api.nvim_create_autocmd({ 'BufEnter', 'FocusGained' }, {
    callback = function()
      maybe_update_branch_status()
    end,
  })

  local MINUTE = 60000
  local minute_timer = vim.uv.new_timer()
  if minute_timer then
    minute_timer:start(
      MINUTE,
      MINUTE,
      vim.schedule_wrap(function()
        vim.g.time = modules._time()
      end)
    )
  end
end

--- builts a statusline section, with its segments separated by the separator
---@alias Direction 'left' | 'right'
---@param segments string[]
---@param direction Direction
local function _build_section(segments, direction)
  local separator = direction == 'left' and LEFT_SEPARATOR or RIGHT_SEPARATOR
  local section = ''
  local has_content = false
  for _, segment in ipairs(segments) do
    local include = #segment > 0 and segment ~= ' '

    if include then
      if has_content then
        section = section .. separator
      end
      section = section .. segment
      has_content = true
    end
  end
  return section
end

function _G.MyStatusLine()
  -- return default statusline if big file
  if not vim.g.statusline or vim.bo.filetype == 'dbout' then
    return hl(vim.g.hl.text.secondary, ' %f')
  end

  if vim.g.zen_mode then
    return ''
  end

  local branch = modules._git_branch()
  local branch_sync_status = modules._branch_sync_status()
  local file = vim.b.cached_file or modules._file()
  local git_status = vim.b.cached_git_status or modules._git_status()
  local diagnostics = vim.b.cached_diagnostics or modules._diagnostics()
  local lsp = vim.b.cached_lsps or modules._lsps()
  local formatters = vim.b.cached_formatters or modules._formatters()
  local macro = modules._macro()
  local terminal = modules._terminal()
  local location = modules._location()
  local time = (not vim.g.statusline_show_time and '') or (vim.g.time or modules._time())
  local search_results = modules._search_results()

  local left = _build_section({ branch .. branch_sync_status, file .. git_status, diagnostics, search_results }, 'left')
  local right = _build_section({ macro, terminal, location, formatters, lsp, time }, 'right')
  local SPACE_BETWEEN = '%=' --- :h statusline

  return string.format('%s%s%s%s%s', LEFT_PREFIX, left, SPACE_BETWEEN, right, RIGHT_SUFFIX)
end

vim.opt.statusline = '%!v:lua.MyStatusLine()'

setup_caching_and_updating()
