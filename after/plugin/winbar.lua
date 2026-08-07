--- Lightweight dropbar.nvim replacement: renders the current file path as a
--- segmented winbar above the window, e.g. `after  plugin  󰢱 winbar.lua`.
--- Path is relative to cwd when the file lives under it, absolute otherwise.
--- Each window renders its own buffer's path, resolved via g:statusline_winid.

local SPECIAL_FT_WINBARS = {
  markdown = ' ',
}

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
  -- `%!` expressions are evaluated in the context of the *current* (focused)
  -- window, so resolve the window this bar belongs to via g:statusline_winid.
  local winid = vim.g.statusline_winid
  if not winid or not vim.api.nvim_win_is_valid(winid) then
    winid = vim.api.nvim_get_current_win()
  end

  local buf = vim.api.nvim_win_get_buf(winid)
  if vim.bo[buf].buftype ~= '' then
    return ''
  end

  local name = vim.api.nvim_buf_get_name(buf)
  if name == '' then
    return ''
  end

  -- relative to the window's cwd (respects :lcd), absolute otherwise
  local abs = vim.fn.fnamemodify(name, ':p')
  local cwd = vim.fn.getcwd(winid)
  local path = abs
  if cwd ~= '' and abs:sub(1, #cwd + 1) == cwd .. '/' then
    path = abs:sub(#cwd + 2)
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

vim.api.nvim_create_autocmd({ 'BufWinEnter', 'WinEnter' }, {
  group = vim.api.nvim_create_augroup('Winbar', { clear = true }),
  callback = function()
    local bufnr = vim.api.nvim_get_current_buf()
    local winid = vim.api.nvim_get_current_win()
    local filetype = vim.bo[bufnr].filetype

    for ft, text in pairs(SPECIAL_FT_WINBARS) do
      if filetype == ft then
        vim.wo[winid].winbar = text
        return
      end
    end

    vim.wo[winid].winbar = '%!v:lua.get_dropbar_winbar()'
  end,
})
