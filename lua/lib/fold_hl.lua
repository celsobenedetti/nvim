--- @class LibFoldHl
--- One background per closed fold line, everywhere.
---
--- `Folded` is the *lowest* layer nvim paints on a closed fold, not the
--- highest: syntax, treesitter, range extmarks with `hl_eol` and
--- `line_hl_group` all draw over it. A folded line therefore ends up with two
--- or three backgrounds — the fugitive filepath bar's header bg for the width
--- of the `diff --git` text and `Folded` for the rest, or a render-markdown
--- heading's own bg and `Folded` past it.
---
--- Measured background precedence on a closed fold line, highest first:
---   1. overlay `virt_text` chunk carrying its own bg  (unbeatable)
---   2. `line_hl_group`, highest priority wins
---   3. range `hl_group` / `hl_eol`
---   4. syntax / treesitter
---   5. `Folded`
---
--- So the deterministic lever is (2): a persistent, background-only
--- `line_hl_group` extmark at near-max priority on each closed fold's first
--- line. It overrides every layer below it across the full window width and
--- sets no foreground, so treesitter and plugin text colors survive. Ephemeral
--- marks are ignored on fold lines, so these have to be real extmarks.
--- Overlay virt_text (heading icons, the bar's own chunks) still shows through
--- — that is only fixable where the chunk is built, by leaving its bg unset.
local M = {}

--- Just under the 65535 ceiling, so a decoration that really must win still
--- can by asking for the maximum.
local PRIORITY = 65534

--- winid -> { ns = integer, buf = integer|nil, sig = string|nil }
local state = {}

--- Namespaces cannot be deleted, so ids from closed windows are recycled.
local free_ns = {}
local ns_count = 0

--- Whether per-window namespace scoping is available (still experimental).
--- Without it every window shares one namespace, so the same buffer shown in
--- two windows with different folds gets whichever window redrew last.
local scoped = vim.api.nvim__ns_set ~= nil
local shared_ns

--- source group -> bg-only derived group name, or `false` when the source has
--- no background to spread. Dropped on `ColorScheme`.
local flat = {}

local provider_ns = vim.api.nvim_create_namespace('fold_hl')

--- Deliberately not named `nvim.*`: nvim-treesitter-context mirrors extmarks
--- from `nvim.` namespaces into its context window, where a fold background
--- has no business.
---@param win integer
---@return integer
local function acquire_ns(win)
  if not scoped then
    shared_ns = shared_ns or vim.api.nvim_create_namespace('fold_hl.shared')
    return shared_ns
  end
  local ns = table.remove(free_ns)
  if not ns then
    ns_count = ns_count + 1
    ns = vim.api.nvim_create_namespace('fold_hl.' .. ns_count)
  end
  vim.api.nvim__ns_set(ns, { wins = { win } })
  return ns
end

--- The bg-only group to stamp in `win`: a copy of `Folded`, or of whatever
--- 'winhighlight' remaps `Folded` to there. That remap is how a buffer opts
--- into its own fold surface (`Folded:DiffFolded` in after/ftplugin/git.lua)
--- and it keeps working unchanged. Only the background is copied, so the fold
--- line's foregrounds stay whatever drew them.
---@param win integer
---@return string|nil group nil when the source group has no background
local function flat_group(win)
  local src = 'Folded'
  for _, pair in ipairs(vim.split(vim.wo[win].winhighlight, ',', { plain = true })) do
    local to = pair:match('^Folded:(.+)$')
    if to then
      src = to
    end
  end

  local name = flat[src]
  if name == nil then
    local hl = vim.api.nvim_get_hl(0, { name = src, link = false })
    name = hl.bg and ('FoldFlat' .. src:gsub('%W', '')) or false
    if name then
      vim.api.nvim_set_hl(0, name, { bg = hl.bg })
    end
    flat[src] = name
  end
  return name or nil
end

--- Closed folds around `win`'s viewport. Bounded by one screenful either side:
--- stamps are only ever seen on screen, and scrolling restamps.
---@param win integer
---@return integer[] rows 0-indexed first line of each closed fold
local function fold_rows(win)
  local rows = {}
  vim.api.nvim_win_call(win, function()
    local height = vim.api.nvim_win_get_height(win)
    local first = math.max(1, vim.fn.line('w0') - height)
    local last = math.min(vim.fn.line('$'), vim.fn.line('w$') + height)

    -- The fold under the cursor keeps its 'cursorline' background: a stamp
    -- outranks CursorLine, and hiding where the cursor sits costs more than
    -- one inconsistent line buys.
    local skip = -1
    if win == vim.api.nvim_get_current_win() and vim.wo[win].cursorline then
      skip = vim.fn.foldclosed(vim.fn.line('.'))
    end

    local lnum = first
    while lnum <= last do
      local start = vim.fn.foldclosed(lnum)
      if start == -1 then
        lnum = lnum + 1
      else
        if start ~= skip then
          rows[#rows + 1] = start - 1
        end
        lnum = vim.fn.foldclosedend(lnum) + 1
      end
    end
  end)
  return rows
end

--- Re-stamp `win` from scratch. Safe to call at any time; the provider below
--- calls it only when the window's fold state actually changed.
---@param win integer
M.refresh = function(win)
  if not vim.api.nvim_win_is_valid(win) then
    return
  end
  local st = state[win]
  if not st then
    st = { ns = acquire_ns(win) }
    state[win] = st
  end

  local buf = vim.api.nvim_win_get_buf(win)
  -- The window moved to another buffer: its stamps stayed behind there.
  if st.buf and st.buf ~= buf and vim.api.nvim_buf_is_valid(st.buf) then
    vim.api.nvim_buf_clear_namespace(st.buf, st.ns, 0, -1)
  end
  st.buf = buf
  vim.api.nvim_buf_clear_namespace(buf, st.ns, 0, -1)

  local group = flat_group(win)
  if not group or vim.b[buf].fold_hl_disable then
    return
  end
  for _, row in ipairs(fold_rows(win)) do
    vim.api.nvim_buf_set_extmark(buf, st.ns, row, 0, { line_hl_group = group, priority = PRIORITY })
  end
end

local pending = {}
local scheduled = false

local function flush()
  scheduled = false
  local wins = pending
  pending = {}
  for win in pairs(wins) do
    M.refresh(win)
  end
end

--- A cheap per-window fingerprint of "which lines are folded". Everything in
--- it is window-accurate without switching windows, which matters because
--- `foldclosed()` inside a decoration provider answers for the *current*
--- window, not the one being redrawn. `nvim_win_text_height` is fold-aware,
--- so it moves whenever a fold in view opens or closes.
---@return string
local function signature(win, buf, topline, botline)
  botline = math.max(topline, math.min(botline, vim.api.nvim_buf_line_count(buf) - 1))
  local ok, height = pcall(vim.api.nvim_win_text_height, win, { start_row = topline, end_row = botline })
  local cursor = ''
  if win == vim.api.nvim_get_current_win() and vim.wo[win].cursorline then
    cursor = vim.api.nvim_win_get_cursor(win)[1]
  end
  local ticks = vim.api.nvim_buf_get_changedtick(buf)
  return table.concat({ topline, botline, ok and height.all or -1, ticks, cursor }, ':')
end

--- Folds have no change event, so redraws are the signal. The provider only
--- fingerprints; the stamping happens in `vim.schedule` where `nvim_win_call`
--- is legal, which costs one frame of lag after a fold toggles.
local function on_win(_, win, buf, topline, botline)
  local st = state[win]
  local sig = signature(win, buf, topline, botline)
  if st and st.sig == sig and st.buf == buf then
    return
  end
  if st then
    st.sig = sig
  else
    state[win] = { ns = acquire_ns(win), sig = sig }
  end
  pending[win] = true
  if not scheduled then
    scheduled = true
    vim.schedule(flush)
  end
end

local enabled = false

M.setup = function()
  if enabled then
    return
  end
  enabled = true
  vim.api.nvim_set_decoration_provider(provider_ns, { on_win = on_win })

  local augroup = vim.api.nvim_create_augroup('FoldHl', { clear = true })
  vim.api.nvim_create_autocmd('WinClosed', {
    group = augroup,
    callback = function(ev)
      local win = tonumber(ev.match)
      local st = win and state[win]
      if not st then
        return
      end
      if st.buf and vim.api.nvim_buf_is_valid(st.buf) then
        vim.api.nvim_buf_clear_namespace(st.buf, st.ns, 0, -1)
      end
      state[win] = nil
      if scoped then
        free_ns[#free_ns + 1] = st.ns
      end
    end,
  })
  vim.api.nvim_create_autocmd('ColorScheme', {
    group = augroup,
    callback = function()
      -- `:colorscheme` wipes the derived groups too; both they and the
      -- fingerprints are rebuilt on the next redraw.
      flat = {}
      for _, st in pairs(state) do
        st.sig = nil
      end
    end,
  })
end

return M
