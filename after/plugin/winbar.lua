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
---
--- Terminal windows get a label instead of a path: `   terminal`, suffixed
--- with the terminal kind (`toggle term`, or `󰚩 pi`-style agent labels for
--- claude/opencode/pi). The label is built by `get_terminal_label`, shared
--- with lib.tab so tabs and winbars agree on terminal names.

local SEP = ((config.icons or {}).separator or {}).right or '  '

-- per-agent glyphs for agent terminals (agent cmd -> icon)
-- git glyph shared by the qf breadcrumb bars (Gclog stamp and :Diff bar)
local GIT_ICON = ((config.icons or {}).git or {}).git or ''

--- Terminal label for a buffer: `   terminal`, plus a segment naming the
--- kind: `toggle term`, or `<icon> <agent>` for agent terminals (claude,
--- opencode, pi). Shared with lib.tab so tabs and winbars agree.
---@param bufnr? number defaults to the current buffer
---@return string
_G.get_terminal_label = function(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  local text = '  terminal'
  if lib.term.is_toggle_term(bufnr) then
    return text .. SEP .. 'toggle term'
  end

  local agent = (lib.term.is_claude(bufnr) and 'claude')
    or (lib.term.is_opencode(bufnr) and 'opencode')
    or (lib.term.is_pi(bufnr) and 'pi')
  if agent then
    return text .. SEP .. config.icons.agent .. ' ' .. agent
  end

  return text
end

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
  ['cmd-output'] = function(buf)
    -- Buffers are named `[cmd] <cmd>` by after/plugin/cmd-output.lua.
    -- nvim_buf_set_name resolves the name against cwd, so the marker is
    -- embedded in an absolute path rather than leading it.
    local cmd = vim.api.nvim_buf_get_name(buf):match('.*%[cmd%] (.*)$') or ''
    return ' ' .. config.icons.cmd .. cmd:gsub('%%', '%%%%')
  end,
  snacks_picker_input = '',
  terminal = function(buf)
    return _G.get_terminal_label(buf)
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
  -- Per-buffer winbar override (e.g. the fugitive :Gclog quickfix bar below).
  -- Keyed off the *window's* buffer, not the current one: g:statusline_winid
  -- makes this run for every window on redraw, so a current-buffer read
  -- (vim.b.winbar) would leak the override into every other split, and the
  -- owning window's bar would vanish as soon as the buffer lost focus.
  -- Quickfix windows: always lead with the qf buffer's own (special) name
  -- — `[Quickfix List]`, or `[Location List]` for location lists
  -- (buf_spname in buffer.c; not exposed by nvim_buf_get_name). Then the
  -- breadcrumb tail — the fugitive Gclog stamp (vim.b override) or the
  -- :Diff list's registered bar (lib.Diff.winbar_text, resolved by current
  -- list id at render time, so nothing needs clearing: a new list has a new
  -- id and simply doesn't match). Lists without a tail show just the name.
  if vim.bo[buf].buftype == 'quickfix' then
    local wininfo = vim.fn.getwininfo(winid)[1]
    local name = wininfo and wininfo.loclist == 1 and '[Location List]' or '[Quickfix List]'
    local qfid = vim.fn.getqflist({ id = 0 }).id
    local tail = vim.b[buf].winbar or (qfid ~= 0 and lib.Diff.winbar_text(qfid))
    return lib.strings.hl('WinBar', tail and (name .. ' > ' .. tail) or name)
  end

  if vim.b[buf].winbar then
    return lib.strings.hl('WinBar', vim.b[buf].winbar)
  end

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

    -- Skip windows that can't hold a winbar. Setting one on a floating window
    -- with view height <= 1 makes nvim raise E36 "Not enough room" inside the
    -- BufWinEnter autocmds, aborting the caller's nvim_open_win (snacks
    -- picker input window, blink.cmp completion float). Scratch buffers
    -- (nofile: pickers, cmp, notifier) render an empty bar anyway, so leave
    -- them alone as well.
    local buf = vim.api.nvim_win_get_buf(winid)
    if vim.bo[buf].buftype == 'nofile' then
      return
    end
    local is_float = vim.api.nvim_win_get_config(winid).relative ~= ''
    if is_float and vim.fn.winheight(winid) <= 1 then
      return
    end

    vim.wo[winid].winbar = WINBAR_EXPR
  end,
})

-- Fugitive's :Gclog fills the quickfix list with log entries; stamp that qf
-- buffer with its own breadcrumb winbar (` qf >  git >  git log`) instead
-- of the empty bar quickfix windows otherwise get (buftype 'quickfix'
-- renders ''). Rendered via the per-buffer vim.b[buf].winbar override in
-- get_winbar() above.
--
-- Fugitive fires `QuickFixCmdPost cfugitive-log` for :Gclog (`lfugitive-log`
-- for :Gllog's location list, `cfugitive-difftool` for :Gdiff's qf). At that
-- point the qf window is open but fugitive has already switched back to the
-- invoking window, so target the qf buffer via getwininfo() rather than
-- vim.b. Any other quickfix command clears the override: the qf buffer is
-- reused across lists, so a later :grep would otherwise inherit the stale
-- git-log bar.
local FUGITIVE_LOG_WINBAR = GIT_ICON .. ' git log'

vim.api.nvim_create_autocmd('QuickFixCmdPost', {
  group = 'Winbar',
  pattern = '*',
  callback = function(args)
    local winbar = args.match == 'cfugitive-log' and FUGITIVE_LOG_WINBAR or nil
    for _, info in ipairs(vim.fn.getwininfo()) do
      if info.quickfix == 1 then
        vim.b[info.bufnr].winbar = winbar
      end
    end
  end,
})
