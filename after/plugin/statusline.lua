local has_icons, devicons = pcall(require, 'nvim-web-devicons')
local hl = require('lib.strings').hl

local icons = vim.g.icons
local HIGHLIGHT = vim.g.hl.subtext
local LEFT_SEPARATOR = hl(HIGHLIGHT, icons.separator.right)
local RIGHT_SEPARATOR = hl(HIGHLIGHT, icons.separator.left)

local function _git_branch()
  if not vim.g.gitsigns_head or #vim.g.gitsigns_head == 0 then
    return ''
  end
  return ' ' .. hl('Title', icons.git.branch) .. hl(HIGHLIGHT, (vim.g.gitsigns_head or ''))
end

local function _file()
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
end

local function _git_status()
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
end

local function _lsps()
  local bufnr = vim.api.nvim_get_current_buf()
  local clients = vim.lsp.get_clients({ bufnr = bufnr })
  if next(clients) == nil then
    return ''
  end

  local c = {}
  for _, client in pairs(clients) do
    table.insert(c, client.name)
  end
  return hl('Title', icons.lsp) .. hl(HIGHLIGHT, table.concat(vim.fn.reverse(c), ', '))
end

local function _formatters()
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
  local result = table.concat(c, ',')
  if #result == 0 then
    return ''
  end

  return hl('Title', ' ') .. hl(HIGHLIGHT, result)
end

local function _diagnostics()
  local count = { 0, 0, 0, 0 } -- error, warn, info, hint
  for _, diagnostic in pairs(vim.diagnostic.get(vim.api.nvim_get_current_buf())) do
    count[diagnostic.severity] = count[diagnostic.severity] + 1
  end
  local result = ''
  -- stylua: ignore start
  if count[1] > 0 then result = result .. hl('DiagnosticError', icons.diagnostics.error .. tostring(count[1]) .. ' ') end
  if count[2] > 0 then result = result .. hl('DiagnosticWarn', icons.diagnostics.warn .. tostring(count[2]) .. ' ') end
  if count[3] > 0 then result = result .. hl('DiagnosticInfo', icons.diagnostics.info .. tostring(count[3]) .. ' ') end
  if count[4] > 0 then result = result .. hl('DiagnosticHint', icons.diagnostics.hint .. tostring(count[4]) .. ' ') end
  -- stylua: ignore end
  return result
end

-- Cache LSP clients on attach/detach
vim.api.nvim_create_autocmd({ 'LspAttach', 'LspDetach' }, {
  callback = function(args)
    local bufnr = args.buf
    vim.api.nvim_buf_set_var(bufnr, 'cached_lsps', _lsps())
  end,
})

-- Cache formatters and file on buffer enter
vim.api.nvim_create_autocmd('BufEnter', {
  callback = function()
    local bufnr = vim.api.nvim_get_current_buf()
    vim.api.nvim_buf_set_var(bufnr, 'cached_formatters', _formatters())
    vim.api.nvim_buf_set_var(bufnr, 'cached_file', _file())
  end,
})

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
  local branch = _git_branch()
  local file = vim.b.cached_file or _file()
  local git_status = _git_status()
  local diagnostics = _diagnostics()
  local lsp = vim.b.cached_lsps or _lsps()
  local formatters = vim.b.cached_formatters or _formatters()

  local left = _build_section({ branch, file .. git_status, diagnostics }, 'left')
  local right = _build_section({ formatters, lsp }, 'right')

  return left .. '%=' .. right
end

vim.opt.statusline = '%!v:lua.MyStatusLine()'
