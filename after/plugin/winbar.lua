--- Lightweight dropbar.nvim replacement: renders the current file path as a
--- segmented winbar above the window, e.g. `after  plugin  󰢱 winbar.lua`.
--- Path is relative to cwd when the file lives under it, absolute otherwise.
--- Each window shows its own buffer's path (native winbar semantics).

local strings = require('lib.strings')
local SEP = ((vim.g.icons or {}).separator or {}).right or '  '

local has_icons, mini_icons = pcall(require, 'mini.icons')

---@param category 'file' | 'directory'
---@param name string
---@return string glyph
---@return string|nil hl
local function get_icon(category, name)
  if not has_icons then
    return '', nil
  end
  local glyph, hl = mini_icons.get(category, name)
  return glyph or '', hl
end

---@param name string
---@param category 'file' | 'directory'
---@return string
local function segment(name, category)
  local glyph, hl = get_icon(category, name)
  local text = name:gsub('%%', '%%%%') -- escape statusline % sequences
  if glyph ~= '' and category == 'file' then
    text = glyph .. ' ' .. text
  end
  return strings.hl(hl or 'WinBar', text)
end

---@return string
_G.get_dropbar_winbar = function()
  local buf = vim.api.nvim_get_current_buf()
  if vim.bo[buf].buftype ~= '' then
    return ''
  end

  local path = vim.fn.expand('%:.') -- relative to cwd, absolute otherwise
  if path == '' then
    return ''
  end

  local segments = vim.split(path, '/', { plain = true })
  if segments[1] == '' then
    table.remove(segments, 1) -- strip leading '/' of absolute paths
  end
  if #segments == 0 then
    return ''
  end

  local parts = {}
  for i = 1, #segments - 1 do
    parts[#parts + 1] = segment(segments[i], 'directory')
  end
  parts[#parts + 1] = segment(segments[#segments], 'file')

  return ' ' .. table.concat(parts, strings.hl('WinBar', SEP))
end

vim.opt.winbar = '%!v:lua.get_dropbar_winbar()'
