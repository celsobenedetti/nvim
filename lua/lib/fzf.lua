---@class LibFzf
local M = {}

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
    profile = 'ivy',
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
      return {
        row = 1, -- bottom edge
        col = 0, -- left edge
        width = 1,
        height = 0.3,
        border = 'none',
        backdrop = 100, -- fully transparent, i.e. no backdrop
        preview = { hidden = true },
      }
    end,
  }, opts or {})
end

return M
