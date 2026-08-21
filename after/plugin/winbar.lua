--- @module 'winbar' home-cooked winbar plugin
--- Lightweight dropbar.nvim replacement: renders the current file path as a
--- segmented winbar above the window, e.g. `after  plugin  󰢱 winbar.lua`.
---
--- 1. Every window's winbar is the `%!` expression below, re-evaluated on each
--- redraw, so the bar always reflects the buffer's current state. Neovim sets
--- g:statusline_winid to the window being drawn, so unfocused windows resolve
--- their own buffer (see statusline.c: set_var before eval).
--- 2. Path is relative to cwd when the file lives under it, absolute otherwise.
--- 3. ft icons resolved via mini.icons.

local SEP = ((config.icons or {}).separator or {}).right or '  '

-- winbar content for specific filetypes. Functions receive the buffer being
-- rendered — the *window's* buffer, which may differ from the focused one.
--
-- These are resolved inside get_winbar() (at render time) rather than set as
-- static strings at BufWinEnter: a fresh `:term` gets its filetype only in
-- TermOpen, which fires *after* BufWinEnter, so a BufWinEnter-time check would
-- miss it and install the generic path bar (which renders '' for terminal
-- buftype). Evaluating per-redraw sidesteps the ordering entirely.
local SPECIAL_FILETYPES = {
  fugitive = ' git' .. SEP .. ' fugitive',
  snacks_picker_input = '',
  terminal = function(buf)
    local text = '  terminal'
    if lib.term.is_toggle_term(buf) then
      return text .. SEP .. 'toggle term'
    end
    if lib.term.is_claude(buf) then
      return text .. SEP .. '󱙺 claude'
    end
    if lib.term.is_opencode(buf) then
      return text .. SEP .. '󱙺 opencode'
    end
    return text
  end,
  git = function(buf)
    local ok, result = pcall(vim.fn.FugitiveResult, buf)
    local command = 'git'
    if ok and #(result.args or {}) > 0 then
      command = command .. ' ' .. table.concat(result.args, ' ')
    end
    return '   ' .. command:gsub('%%', '%%%%')
  end,
}

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
  if category == 'directory' then
    hl = 'Normal'
  end
  return lib.strings.hl(hl or 'WinBar', text)
end

---@return string
_G.get_winbar = function()
  -- Neovim sets g:statusline_winid to the window being drawn while evaluating
  -- its winbar, so resolve the window this bar belongs to via that variable.
  local winid = vim.g.statusline_winid
  if not winid or not vim.api.nvim_win_is_valid(winid) then
    winid = vim.api.nvim_get_current_win()
  end

  local buf = vim.api.nvim_win_get_buf(winid)

  -- Special filetypes first: their content depends on live buffer state (e.g.
  -- which terminal kind), and filetype may only be set after the winbar was
  -- installed (TermOpen fires after BufWinEnter for a fresh `:term`).
  local special = SPECIAL_FILETYPES[vim.bo[buf].filetype]
  if special ~= nil then
    if type(special) == 'function' then
      return special(buf)
    end
    return special
  end

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

  return ' ' .. table.concat(parts, lib.strings.hl('WinBar', SEP))
end

local WINBAR_EXPR = '%!v:lua.get_winbar()'

vim.api.nvim_create_autocmd({ 'BufWinEnter', 'WinEnter' }, {
  group = vim.api.nvim_create_augroup('Winbar', { clear = true }),
  callback = function()
    -- BufWinEnter covers buffer switches in the same window; WinEnter covers
    -- entering a new window (e.g. a fresh split). Both install the same `%!`
    -- expression, so the bar is re-derived from live state on the next redraw.
    --
    -- Windows whose winbar is neither empty nor ours are left alone: a plugin
    -- owns that bar (oil sets %!v:lua.get_oil_winbar() the moment its buffer is
    -- shown, and its buftype is not yet 'nofile' at BufWinEnter), and we'd
    -- clobber it otherwise.
    local winid = vim.api.nvim_get_current_win()
    local winbar = vim.wo[winid].winbar
    if winbar ~= '' and winbar ~= WINBAR_EXPR then
      return
    end

    vim.wo[winid].winbar = WINBAR_EXPR
  end,
})
