---@class LibFzf
local M = {}

---fd command listing files, symlinks and directories: hidden files, no
---gitignore, minus a few heavy dirs (same rules as the `<c-p>` picker).
M.fd_files_dirs_cmd = function()
  return string.gsub('fd --color=never --type f --type l --type d --hidden --follow' .. config.cmd.fd.ignore, '\n', ' ')
end

---Resolve the first selection of an fzf-lua file action to an absolute path
---(fzf-lua returns cwd-relative entries; joining against the picker's cwd
---makes them absolute).
---@param selected string[]
---@param opts table fzf-lua action opts
---@return string|nil
M.selected_path = function(selected, opts)
  local fzfpath = require('fzf-lua.path')
  if #selected == 0 then
    return nil
  end
  local entry = fzfpath.entry_to_file(selected[1], opts, opts._uri)
  local full = entry.path
  if full and not fzfpath.is_absolute(full) then
    full = fzfpath.join({ opts.cwd or opts._cwd or vim.uv.cwd(), full })
  end
  return full
end

---Yank `text` to the unnamed register, and to `*`/`+` too if 'clipboard'
---says so (mirrors fzf-lua's own `git_yank_commit`).
---@param text string
M.set_yank_regs = function(text)
  local regs, cb = {}, vim.o.clipboard
  if cb:match('unnamed') then regs[#regs + 1] = '*' end
  if cb:match('unnamedplus') then regs[#regs + 1] = '+' end
  if #regs == 0 then regs[#regs + 1] = '"' end
  for _, reg in ipairs(regs) do
    vim.fn.setreg(reg, text)
  end
  vim.fn.setreg('0', text)
  vim.notify('yanked: ' .. text, vim.log.levels.INFO)
end

---Yank the highlighted fzf-lua entry: the resolved file path (plus line
---number, for file:line entries) when the line looks like one, otherwise the
---raw display text with ansi codes stripped.
---@param selected string[]
---@param opts table fzf-lua action opts
M.yank_entry = function(selected, opts)
  local line = selected and selected[1]
  if not line then
    return
  end
  local fzf = require('fzf-lua')
  local ok, entry = pcall(require('fzf-lua.path').entry_to_file, line, opts)
  local text
  if ok and entry.path then
    -- `entry.line` defaults to 0 (not nil) when the entry has no line number
    text = entry.path .. (entry.line and entry.line ~= 0 and (':' .. entry.line) or '')
  else
    text = fzf.utils.strip_ansi_coloring(line):match('^%s*(.-)%s*$')
  end
  M.set_yank_regs(text)
end

--- search entries with fzf-lua
--- runs the command once and fuzzy-filters the results in fzf (like the
--- Snacks static-item picker), with native file:line preview and jump.
---@param opts {cwd?: string, cmd?: string[]}
M.grep = function(opts)
  opts = opts or {}
  local cmd = opts.cmd or { 'git', '-C', '%s', 'grep', '--line-number', '.', opts.cwd or '.' }

  local parts = {}
  for _, arg in ipairs(cmd) do
    parts[#parts + 1] = vim.fn.shellescape(arg)
  end

  local fzf = require('fzf-lua')
  fzf.grep({
    raw_cmd = table.concat(parts, ' '),
    cwd = opts.cwd,
    -- profile = 'ivy',
    actions = {
      -- alt-q: send ALL filtered results to the quickfix list (not just the
      -- highlighted/selected entries). `prefix = 'select-all'` marks every
      -- match before the send, giving the "dump grep hits to qf" behavior.
      -- (Default alt-q only sends the current/tab-selected entries.)
      ['alt-q'] = { fn = fzf.actions.file_sel_to_qf, prefix = 'select-all' },
    },
    winopts = { title = 'grep ' .. (opts.cwd or '') },
  })
end

-- Mimics the `:e` picker layout: anchored bottom-left,
-- no border/backdrop chrome, results growing upward from the prompt line.
-- fzf-lua already defaults to `--layout=reverse` (list grows up), so this only
-- needs to set window geometry.
--
-- This is a pseudo-profile, not a real fzf-lua `profile` (those can only be a
-- string like `profile = 'ivy'`): fzf-lua resolves them via `dofile` against
-- its own plugin directory (see fzf-lua/utils.lua load_profiles), so a
-- user-defined profile would have to live inside the lazy-managed plugin
-- install dir and get wiped on every update. `M.e(opts)` merges the `:e`
-- winopts with any extra picker opts, mirroring how a real profile is used.
---@param opts table?
M.e = function(opts)
  return vim.tbl_extend('force', {
    previewer = false,
    fzf_opts = { ['--layout'] = 'default' },
    winopts = function()
      local cols = vim.o.columns
      return {
        row = 0.96, -- bottom edge
        col = 0, -- left edge
        width = math.max(0.6, 60 / cols), -- 40% width, at least 60 cols
        height = 0.3,
        border = 'none',
        backdrop = 100, -- fully transparent, i.e. no backdrop
        preview = { hidden = true },
      }
    end,
  }, opts or {})
end

return M
