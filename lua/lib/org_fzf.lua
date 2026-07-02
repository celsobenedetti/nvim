--- fzf-lua integration for nvim-orgmode.
---
--- A minimal, self-contained port of telescope-orgmode.nvim exposing only the
--- two entry points I actually use:
---   * search_headings() — fuzzy-find any headline and jump to it
---   * refile_heading()  — refile the headline under the cursor to a chosen target
---
--- Headlines are loaded once from the orgmode API and fuzzy-filtered inside fzf
--- (the "static item" pattern), with native file:line preview. Each entry is
--- prefixed with a hidden tab-delimited index so we can round-trip back to the
--- exact headline regardless of duplicate titles; the index column is hidden
--- from both display and search via `--with-nth`/`--nth`.

local M = {}

local function fzf()
  return require('fzf-lua')
end

local function OrgApi()
  return require('orgmode.api')
end

-- Custom builtin previewer that resolves a fzf line back to a file:line through
-- the item list stashed on `opts._org_items` (keyed by the hidden index field).
local _Previewer
local function previewer()
  if _Previewer then
    return _Previewer
  end
  local builtin = require('fzf-lua.previewer.builtin')
  local P = builtin.buffer_or_file:extend()

  function P:new(...)
    P.super.new(self, ...)
    setmetatable(self, P)
    return self
  end

  function P:entry_to_file(entry_str)
    local idx = tonumber(entry_str:match('^(%d+)'))
    local item = idx and self.opts._org_items[idx]
    if not item then
      return { path = nil, line = 1, col = 1 }
    end
    return { path = item.filename, line = item.line_number or 1, col = 1 }
  end

  _Previewer = P
  return P
end

---------------------------------------------------------------------------
-- Loading headlines from the orgmode API
---------------------------------------------------------------------------

--- Agenda files sorted most-recently-modified first, archives dropped unless asked.
---@param opts { archived?: boolean, only_current_file?: boolean, current_file?: string }
local function org_files(opts)
  local files = require('orgmode').files:all()

  if opts.only_current_file then
    local current = opts.current_file or vim.api.nvim_buf_get_name(0)
    files = vim.tbl_filter(function(file)
      return file.filename == current
    end, files)
  end

  if not opts.archived then
    files = vim.tbl_filter(function(file)
      return vim.fn.fnamemodify(file.filename, ':e') ~= 'org_archive'
    end, files)
  end

  table.sort(files, function(a, b)
    local sa = vim.uv.fs_stat(a.filename)
    local sb = vim.uv.fs_stat(b.filename)
    return (sa and sa.mtime.sec or 0) > (sb and sb.mtime.sec or 0)
  end)

  return files
end

--- Lightweight headline records (no API-object resolution — that's deferred to
--- selection time so we never pay to load every file up front).
---@param opts { archived?: boolean, only_current_file?: boolean, current_file?: string, max_depth?: number }
local function load_headlines(opts)
  local results = {}
  for _, file in ipairs(org_files(opts)) do
    local headlines = opts.archived and file:get_headlines_including_archived() or file:get_headlines()
    for _, h in ipairs(headlines) do
      if (not opts.max_depth or h:get_level() <= opts.max_depth) and (opts.archived or not h:is_archived()) then
        local todo = h:get_todo()
        local priority = h:get_priority()
        table.insert(results, {
          filename = file.filename,
          line_number = h:get_range().start_line,
          title = h:get_title(),
          level = h:get_level(),
          all_tags = h:get_tags(),
          todo_value = (todo and todo ~= '') and todo or nil,
          todo_type = todo and (h:is_done() and 'DONE' or 'TODO') or nil,
          priority = (priority and priority ~= '') and priority or nil,
        })
      end
    end
  end
  return results
end

---------------------------------------------------------------------------
-- Display formatting
---------------------------------------------------------------------------

local function pad(s, width)
  local diff = width - vim.fn.strdisplaywidth(s)
  return diff > 0 and s .. string.rep(' ', diff) or s
end

local function grey(s)
  return fzf().utils.ansi_codes.grey(s)
end

local function todo_ansi(item)
  if not item.todo_value then
    return ''
  end
  local hl = item.todo_type == 'DONE' and '@org.keyword.done' or '@org.keyword.todo'
  return fzf().utils.ansi_from_hl(hl, item.todo_value)
end

--- Turn headline records into display strings, aligning location and todo
--- columns to the widest entry in the set.
---@param records table[]
---@return table[] items, string[] entries
local function headline_items(records)
  local w_loc, w_todo = 0, 0
  for _, r in ipairs(records) do
    r.location = string.format('%s:%d', vim.fn.fnamemodify(r.filename, ':t'), r.line_number)
    w_loc = math.max(w_loc, vim.fn.strdisplaywidth(r.location))
    if r.todo_value then
      w_todo = math.max(w_todo, vim.fn.strdisplaywidth(r.todo_value))
    end
  end

  local items, entries = {}, {}
  for i, r in ipairs(records) do
    local parts = { grey(pad(r.location, w_loc)), '  ' }
    if w_todo > 0 then
      parts[#parts + 1] = todo_ansi(r) .. string.rep(' ', w_todo - vim.fn.strdisplaywidth(r.todo_value or ''))
      parts[#parts + 1] = ' '
    end
    if r.priority then
      parts[#parts + 1] = fzf().utils.ansi_codes.magenta('[#' .. r.priority .. ']') .. ' '
    end
    parts[#parts + 1] = string.rep('*', r.level) .. ' ' .. r.title
    if #r.all_tags > 0 then
      parts[#parts + 1] = '  ' .. fzf().utils.ansi_from_hl('@org.tag', ':' .. table.concat(r.all_tags, ':') .. ':')
    end

    local display = table.concat(parts)
    items[i] = { filename = r.filename, line_number = r.line_number }
    entries[i] = string.format('%d\t%s', i, display)
  end

  return items, entries
end

--- Org files as top-level refile targets (line_number nil => refile to file root).
---@param opts table
---@return table[] items, string[] entries
local function file_items(opts)
  local items, entries = {}, {}
  for i, file in ipairs(org_files(opts)) do
    local title = file:get_title()
    local name = vim.fn.fnamemodify(file.filename, ':t')
    local display = grey(name) .. (title and title ~= '' and ('  ' .. title) or '')
    items[i] = { filename = file.filename, line_number = nil, is_file = true }
    entries[i] = string.format('%d\t%s', i, display)
  end
  return items, entries
end

---------------------------------------------------------------------------
-- Picker
---------------------------------------------------------------------------

--- Run the static-item picker.
---@param o { items: table[], entries: string[], prompt: string, title: string, on_confirm: fun(item: table) }
local function pick(o)
  fzf().fzf_exec(o.entries, {
    prompt = o.prompt,
    _org_items = o.items,
    previewer = previewer(),
    -- The entry is `<index>\t<display>`. `--with-nth 2..` hides the index from
    -- BOTH the list and the fuzzy match (it reshapes the line to field 2..),
    -- while fzf still returns the full original line so actions/previewer can
    -- recover the index. NB: do NOT also set `--nth` — it would then operate on
    -- the already-reshaped single-field line and match nothing (fzf >= 0.72).
    fzf_opts = {
      ['--delimiter'] = '[\t]',
      ['--with-nth'] = '2..',
      ['--ansi'] = true,
    },
    winopts = { title = o.title },
    actions = {
      ['default'] = function(selected)
        local line = selected and selected[1]
        local idx = line and tonumber(line:match('^(%d+)'))
        local item = idx and o.items[idx]
        if item then
          o.on_confirm(item)
        end
      end,
    },
  })
end

---------------------------------------------------------------------------
-- Public API
---------------------------------------------------------------------------

--- Jump the cursor to a headline chosen from the fuzzy picker.
---@param opts? { archived?: boolean, only_current_file?: boolean, max_depth?: number }
function M.search_headings(opts)
  opts = opts or {}
  opts.current_file = vim.api.nvim_buf_get_name(0)

  local items, entries = headline_items(load_headlines(opts))
  pick({
    items = items,
    entries = entries,
    prompt = 'Headlines> ',
    title = 'Org Headlines',
    on_confirm = function(item)
      vim.cmd("normal! m'") -- push to the jumplist first
      if vim.fn.fnamemodify(item.filename, ':p') ~= vim.fn.expand('%:p') then
        vim.cmd('edit ' .. vim.fn.fnameescape(item.filename))
      end
      vim.api.nvim_win_set_cursor(0, { item.line_number, 0 })
      vim.cmd('normal! zvzz')
    end,
  })
end

--- Resolve a picker item to an OrgApi destination (headline or whole file).
local function resolve_destination(item)
  local file = OrgApi().load(item.filename)
  if not file then
    return nil
  end
  if item.is_file or not item.line_number then
    return file
  end
  for _, headline in ipairs(file.headlines) do
    if headline.position.start_line == item.line_number then
      return headline
    end
  end
  return nil
end

--- Refile the headline under the cursor to a chosen headline or file.
---@param opts? { archived?: boolean }
function M.refile_heading(opts)
  opts = opts or {}
  opts.current_file = vim.api.nvim_buf_get_name(0)

  local source
  if vim.bo.filetype == 'org' then
    local ok, current = pcall(function()
      return OrgApi().current():get_closest_headline()
    end)
    source = ok and current or nil
  elseif vim.bo.filetype == 'orgagenda' then
    local ok, agenda = pcall(require, 'orgmode.api.agenda')
    if ok then
      source = agenda.get_headline_at_cursor()
    end
  end

  if not source then
    vim.notify('No headline under the cursor to refile', vim.log.levels.WARN)
    return
  end

  -- Files first (top-level targets), then every headline.
  local file_it, file_en = file_items(opts)
  local head_it, head_en = headline_items(load_headlines(opts))

  local items, entries = {}, {}
  for i, it in ipairs(file_it) do
    items[i] = it
    entries[i] = string.format('%d\t%s', i, file_en[i]:gsub('^%d+\t', ''))
  end
  local offset = #file_it
  for i, it in ipairs(head_it) do
    items[offset + i] = it
    entries[offset + i] = string.format('%d\t%s', offset + i, head_en[i]:gsub('^%d+\t', ''))
  end

  pick({
    items = items,
    entries = entries,
    prompt = 'Refile to> ',
    title = 'Refile: ' .. source.title,
    on_confirm = function(item)
      vim.schedule(function()
        local destination = resolve_destination(item)
        if not destination then
          vim.notify('Could not resolve refile destination', vim.log.levels.ERROR)
          return
        end
        local ok, result = pcall(function()
          return OrgApi().refile({ source = source, destination = destination }):wait()
        end)
        if ok and result then
          vim.notify('Refiled: ' .. source.title, vim.log.levels.INFO)
        else
          vim.notify('Refile failed' .. (ok and '' or (': ' .. tostring(result))), vim.log.levels.WARN)
        end
      end)
    end,
  })
end

return M
