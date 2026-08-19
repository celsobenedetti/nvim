---@class LibCmdline
local M = {}

-- clear cmdline after 5s
M.clear = function()
  vim.fn.timer_start(5000, function()
    print(' ')
  end)
end

-- ============================================================
-- `<Tab>` on the cmdline: when the line ends in `**`, launch an fzf-lua
-- picker over the files+directories under the typed path (`:e **` searches
-- the cwd). On confirm the `**` token is replaced by the selected path and
-- the rest of the user's command is kept: `:e /some/path/**` runs
-- `:e /some/path/<selected>` and `:Grep query **` runs
-- `:Grep query <selected>`. Any other line falls back to the native cmdline
-- completion via 'wildcharm' (see lua/init/options.lua); feeding '<Tab>'
-- itself would recurse into this very mapping.

---Does `line` end in `**` (the fzf-tab trigger)?
---@param line string cmdline content, without the leading `:`
---@return boolean
M.is_fzf_tab = function(line)
  return line ~= nil and line:match('%*%*$') ~= nil
end

---Split a `**`-terminated cmdline into the user's command (everything up to
---the last token) and the search dir (that token minus the trailing `**`).
---@param line string cmdline content, without the leading `:`
---@return {cmd: string, dir: string}|nil cmd='' when the line is a bare `**`;
---  dir='' means the cwd; nil when `line` isn't a fzf-tab
M.parse = function(line)
  if not M.is_fzf_tab(line) then
    return nil
  end
  local prefix, token = line:match('^(.*)%s+([^%s]-%*%*)$')
  if token == nil then
    -- no whitespace: the whole line is the `**` glob token
    token, prefix = line, ''
  end
  local dir = token:sub(1, -3) -- strip the trailing `**`
  if #dir > 1 and dir:sub(-1) == '/' then
    dir = dir:sub(1, -2) -- drop the trailing slash for display
  end
  return { cmd = prefix:match('^%s*(.-)%s*$'), dir = dir }
end

---Absolute search root for a parsed dir, validated to exist.
---@param dir string '' = cwd
---@return string|nil root, nil when the dir doesn't exist
M.search_root = function(dir)
  if dir == '' then
    return vim.uv.cwd()
  end
  local expanded = vim.fn.expand(dir)
  if vim.fn.isdirectory(expanded) ~= 1 then
    return nil
  end
  return vim.fn.fnamemodify(expanded, ':p')
end

---Feed the default cmdline completion. 'wildcharm' behaves exactly like
---'wildchar' (<Tab>) but only fires from mappings/feedkeys, so this can't
---recurse into the <Tab> mapping; 'i' executes it next, before any queued
---typeahead.
local function fallback_tab()
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<C-z>', true, false, true), 'ni', false)
end

---Cancel the pending cmdline, then launch the picker once back in normal
---mode (a floating window can't open while the cmdline is active).
---@param line string the full cmdline (drives the picker prompt)
---@param parsed {cmd: string, dir: string}
---@param root string absolute search root
local function launch_picker(line, parsed, root)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<C-c>', true, false, true), 'ni', false)
  vim.schedule(function()
    local fzf = require('fzf-lua')
    fzf.files(lib.fzf.e({
      cwd = root,
      cmd = lib.fzf.fd_files_dirs_cmd(),
      prompt = line .. ' > ',
      actions = {
        ['enter'] = function(selected, opts)
          local full = lib.fzf.selected_path(selected, opts)
          if full then
            -- substitute the selected path for the `**` token, keeping the
            -- user's command; a bare `:**` defaults to `:e`
            local ex = parsed.cmd == '' and 'e' or parsed.cmd
            vim.cmd(ex .. ' ' .. vim.fn.fnameescape(full))
          end
        end,
      },
    }))
  end)
end

---`<Tab>` handler for the cmdline (wired in after/plugin/cmdline.lua).
M.fzf_tab = function()
  if vim.fn.getcmdtype() ~= ':' then
    return fallback_tab()
  end
  local line = vim.fn.getcmdline()
  local parsed = M.parse(line)
  if parsed == nil then
    return fallback_tab()
  end
  local root = M.search_root(parsed.dir)
  if root == nil then
    -- the typed path isn't a directory: keep the native completion
    return fallback_tab()
  end
  launch_picker(line, parsed, root)
end

return M
