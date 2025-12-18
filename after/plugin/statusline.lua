---@module 'statusline' home cooked statusline plugin
---@author Celso Benedetti
---@license MIT
---
--- example:
---  main  󰢱 after/plugin/statusline.lua +3 ~1 -1   5  1  1                                                       stylua   lua_ls
---
--- try to cache as much as possible since the statusline is re-rendered on every keystroke

--------------- globals start -----------------------
local has_icons, devicons = pcall(require, 'nvim-web-devicons')
local hl = require('lib.strings').hl
local HIGHLIGHT = vim.g.hl.subtext
local LEFT_SEPARATOR = hl(HIGHLIGHT, vim.g.icons.separator.right)
local RIGHT_SEPARATOR = hl(HIGHLIGHT, vim.g.icons.separator.left)
--------------- globals end -----------------------

local modules = {
  _git_branch = function()
    if not vim.g.gitsigns_head or #vim.g.gitsigns_head == 0 then
      return ''
    end
    return ' ' .. hl('Title', vim.g.icons.git.branch) .. hl(HIGHLIGHT, (vim.g.gitsigns_head or ''))
  end,

  _file = function()
    local relative_file = vim.fn.expand('%:.')
    local icon = ''
    if has_icons then
      local ft_icon, ft_color = devicons.get_icon(relative_file)
      if ft_icon then
        icon = hl(ft_color, ft_icon) .. ' '
      end
    end
    local file = hl(HIGHLIGHT, relative_file)
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
    return hl('Title', vim.g.icons.lsp) .. hl(HIGHLIGHT, table.concat(vim.fn.reverse(c), ', '))
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

    return hl('Title', ' ') .. hl(HIGHLIGHT, result)
  end,

  _diagnostics = function()
    local count = { 0, 0, 0, 0 } -- error, warn, info, hint
    for _, diagnostic in pairs(vim.diagnostic.get(vim.api.nvim_get_current_buf())) do
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
    return hl('MiniStatuslineModeReplace', ' recording macro ')
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

  -- Cache diagnostics and status
  vim.api.nvim_create_autocmd({ 'TextChanged', 'InsertLeave' }, {
    callback = function()
      local bufnr = vim.api.nvim_get_current_buf()
      vim.defer_fn(function()
        pcall(function()
          vim.api.nvim_buf_set_var(bufnr, 'cached_diagnostics', modules._diagnostics())
          vim.api.nvim_buf_set_var(bufnr, 'cached_git_status', modules._git_status())
        end)
      end, 300)
    end,
  })

  -- create scheduler to update some cached items periodically
  local INTERVAL = 2000
  local timer = vim.uv.new_timer()
  if timer then
    timer:start(
      INTERVAL,
      INTERVAL,
      vim.schedule_wrap(function()
        local bufnr = vim.api.nvim_get_current_buf()
        vim.api.nvim_buf_set_var(bufnr, 'cached_diagnostics', modules._diagnostics())
        vim.api.nvim_buf_set_var(bufnr, 'cached_git_status', modules._git_status())
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
  for i, segment in pairs(segments) do
    if #segment > 0 then
      if i > 1 and #section > 0 then
        section = section .. separator
      end
      section = section .. segment
    end
  end
  return section
end

function _G.MyStatusLine()
  local branch = modules._git_branch()
  local file = vim.b.cached_file or modules._file()
  local git_status = vim.b.cached_git_status or modules._git_status()
  local diagnostics = vim.b.cached_diagnostics or modules._diagnostics()
  local lsp = vim.b.cached_lsps or modules._lsps()
  local formatters = vim.b.cached_formatters or modules._formatters()
  local macro = modules._macro()

  local left = _build_section({ branch, file .. git_status, diagnostics }, 'left')
  local right = _build_section({ macro, formatters, lsp }, 'right')

  return left .. '%=' .. right
end

vim.opt.statusline = '%!v:lua.MyStatusLine()'

setup_caching_and_updating()
