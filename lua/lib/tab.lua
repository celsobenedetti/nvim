--- Tab helpers: home-grown tab naming, persisted across sessions.
---@class LibTab
local M = {}

---@type table<number,string> tabpage id -> explicit name
local names = {}

local SEP = ((config.icons or {}).separator or {}).right or '  '

-- specify tab label string or function for specific filetypes, applied when a
-- tab contains a single buffer (analogous to the winbar's SPECIAL_FILETYPES);
-- functions receive the tab's buffer id.
---@type table<string,string|fun(bufnr: number): string>
local SPECIAL_FILETYPES = {
  terminal = function(bufnr)
    local text = config.icons.term .. 'terminal'
    if lib.term.is_toggle_term(bufnr) then
      return text .. SEP .. 'toggle term'
    end
    local agent = (lib.term.is_claude(bufnr) and 'claude')
      or (lib.term.is_opencode(bufnr) and 'opencode')
      or (lib.term.is_pi(bufnr) and 'pi')
    if agent then
      return text .. SEP .. config.icons.agent .. agent
    end
    return text
  end,
}

---@type string?
local pending_name = nil

---@type boolean
local loaded = false

---Buffer shown by a tab when all its windows share a single buffer.
---@param tabid number
---@return number|nil bufnr, or nil when the tab shows several buffers
local function single_buffer_bufnr(tabid)
  local bufs = {}
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tabid)) do
    bufs[vim.api.nvim_win_get_buf(win)] = true
  end
  local keys = vim.tbl_keys(bufs)
  if #keys == 1 then
    return keys[1]
  end
  return nil
end

---Display name for a tab without an explicit one: the basename of the
---buffer shown in the tab's current window, or a filetype-specific label
---when the tab contains a single buffer.
---@param tabid number
---@return string
local function fallback_name(tabid)
  if not vim.api.nvim_tabpage_is_valid(tabid) then
    return ''
  end
  local buf = vim.api.nvim_win_get_buf(vim.api.nvim_tabpage_get_win(tabid))

  local sbuf = single_buffer_bufnr(tabid)
  if sbuf ~= nil then
    local special = SPECIAL_FILETYPES[vim.bo[sbuf].filetype]
    if special ~= nil then
      if type(special) == 'function' then
        return special(sbuf)
      end
      return special
    end
  end

  local name = vim.api.nvim_buf_get_name(buf)
  if name == '' then
    return '[No Name]'
  end
  return vim.fn.fnamemodify(name, ':t')
end

---Load names from `state.NamedTabs`, keyed by tab *number* so they survive
---tabpage id changes after a session restore.
local function load()
  local raw = state.NamedTabs
  if type(raw) ~= 'string' or vim.json == nil then
    return
  end
  local ok, decoded = pcall(function()
    return vim.json.decode(raw)
  end)
  if not ok or type(decoded) ~= 'table' then
    return
  end
  names = {}
  for _, tpid in ipairs(vim.api.nvim_list_tabpages()) do
    local name = decoded[tostring(vim.api.nvim_tabpage_get_number(tpid))]
    if name ~= nil then
      names[tpid] = name
    end
  end
end

---Persist names to `state.NamedTabs`.
local function save()
  local by_number = {}
  for tpid, name in pairs(names) do
    local ok, num = pcall(vim.api.nvim_tabpage_get_number, tpid)
    if ok then
      by_number[tostring(num)] = name
    end
  end
  if vim.json ~= nil then
    state.NamedTabs = vim.json.encode(by_number)
  end
end

local function ensure_loaded()
  if not loaded then
    load()
    loaded = true
  end
end

-- Reload names after a session restore remaps tabpage ids.
if vim.api.nvim_create_autocmd ~= nil then
  vim.api.nvim_create_autocmd('SessionLoadPost', {
    callback = function()
      loaded = false
    end,
  })
end

---Tab naming is built in; always available.
---@return boolean
M.available = function()
  return true
end

---Rename a tab. If `name` is nil/empty, prompts via `vim.ui.input`.
---@param name? string
---@param tabid? number tab id, defaults to the current tab
M.rename = function(name, tabid)
  if name and #name > 0 then
    M.set(name, tabid or 0)
    return
  end
  vim.ui.input({ prompt = 'rename Tab: ' }, function(input)
    if not input or #input == 0 then
      return
    end
    M.set(input, tabid or 0)
  end)
end

---Set a tab's name.
---@param name string
---@param tabid number tab id, 0 for current tab
M.set = function(name, tabid)
  ensure_loaded()
  local id = tabid or 0
  if id == 0 then
    id = vim.api.nvim_get_current_tabpage()
  end
  names[id] = name
  save()
  vim.cmd('redrawtabline')
end

---Get a tab's display name: explicit name or the current window's buffer.
---@param tabid? number tab id, defaults to the current tab
---@return string
M.get_name = function(tabid)
  ensure_loaded()
  local id = tabid or 0
  if id == 0 then
    id = vim.api.nvim_get_current_tabpage()
  end
  if names[id] ~= nil then
    return names[id]
  end
  return fallback_name(id)
end

---Find the first tab whose name matches a plain string.
---@param pattern string literal substring to match
---@return number? tabid, or nil when not found
M.find = function(pattern)
  ensure_loaded()
  for _, tpid in ipairs(vim.api.nvim_list_tabpages()) do
    local name = M.get_name(tpid)
    if name and name:find(pattern, 1, true) then
      return tpid
    end
  end
  return nil
end

---Derive a git/codediff tab name from a command string, e.g. `tab Git show
---abc123` -> ` git show abc123`, `CodeDiff main HEAD` -> ` diff main HEAD`.
---@param last string
---@return string? nil when the command is not a Git/CodeDiff command
M.name_from_command = function(last)
  if last == '' then
    return nil
  end
  local git_args = last:match('^:?%s*tab%s+Git%s+(.*)$') or last:match('^:?%s*Git%s+(.*)$')
  if git_args and git_args ~= '' then
    return config.icons.git.git .. 'git ' .. vim.trim(git_args)
  end
  local cdiff_args = last:match('^:?%s*CodeDiff%s+(.*)$')
  if cdiff_args and cdiff_args ~= '' then
    return config.icons.git.diff .. 'diff ' .. vim.trim(cdiff_args)
  end
  return nil
end

---Queue a tab name to be applied by the next tab that opens (e.g. CodeDiff
---opens asynchronously); consumed via `M.consume_next_name`.
---@param name string
M.set_next_name = function(name)
  pending_name = name
end

---Read and clear the queued tab name.
---@return string?
M.consume_next_name = function()
  local name = pending_name
  pending_name = nil
  return name
end

---Render the tabline (install via
---`vim.o.tabline = "%!v:lua.lib.tab.render()"`).
---@return string
M.render = function()
  ensure_loaded()
  local current = vim.api.nvim_get_current_tabpage()
  local parts = {}
  for i, tpid in ipairs(vim.api.nvim_list_tabpages()) do
    local name = M.get_name(tpid)
    local prefix = ''
    if i == 1 then
      prefix = config.icons.code
    end
    if name:find('lazygit') then
      prefix = config.icons.git.git
    end
    if name:find('claude') then
      prefix = config.icons.agent
    end

    if i > 1 then
      table.insert(parts, '%#Normal# ')
    end
    local num = vim.api.nvim_tabpage_get_number(tpid)
    local hl = tpid == current and 'TabLineSel' or 'TabLine'
    table.insert(parts, string.format('%%#%s# %s%s %%%dT', hl, prefix, name, num))
  end
  table.insert(parts, '%#TabLineFill#%=')
  return table.concat(parts)
end

return M
