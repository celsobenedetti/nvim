local has_icons, devicons = pcall(require, 'nvim-web-devicons')
local hl = require('lib.strings').hl

local icons = vim.g.icons
local HIGHLIGHT = vim.g.hl.subtext

local function _git_branch()
  if not vim.g.gitsigns_head or #vim.g.gitsigns_head == 0 then
    return ''
  end

  return ' ' .. hl('Title', icons.git.branch) .. hl(HIGHLIGHT, (vim.g.gitsigns_head or ''))
end

local function _current_file()
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

local _current_lsps = function()
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

local _current_formatters = function()
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

function _G.MyStatusLine()
  local branch = _git_branch()
  local git_status = _git_status()
  local file = _current_file()
  local lsp = _current_lsps()
  local formatters = _current_formatters()

  local left_separator = ''
  if #branch > 0 and #file > 0 then
    left_separator = hl(HIGHLIGHT, icons.separator.right)
  end

  local right_separator = ''
  if #formatters > 0 then
    right_separator = hl(HIGHLIGHT, icons.separator.left)
  end

  local left = branch .. left_separator .. file .. git_status
  local right = formatters .. right_separator .. lsp

  return left .. '%=' .. right
end

vim.opt.statusline = '%!v:lua.MyStatusLine()'
