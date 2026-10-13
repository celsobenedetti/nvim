local cwd = lib.cwd
local keys = lib.keys

---@class LibFs
local M = {}

--- @return snacks.picker.finder.Item[]
local function get_local_directories_for_snacks()
  local root = cwd.root()
  --- @type snacks.picker.finder.Item[]
  local snack_items = { { text = '.', file = root, dir = root, cmd = root, desc = root } }
  for _, dir in ipairs(cwd.directories({ git = false })) do
    dir = dir .. '/' -- remove trailing slash
    table.insert(snack_items, { text = dir, file = dir, dir = dir, cmd = dir, desc = dir })
  end
  return snack_items
end

M.mv_file = function()
  local dirs = get_local_directories_for_snacks()
  Snacks.picker.pick({
    title = 'Move file to',
    items = dirs,
    confirm = function(picker, item)
      picker:close()

      local destination = item.text
      if not destination then
        return
      end

      local original_buffer = vim.api.nvim_get_current_buf()
      local current_file = vim.api.nvim_buf_get_name(original_buffer)
      local new_file = vim.fs.joinpath(item.dir, vim.fn.fnamemodify(current_file, ':t'))

      local ok, err = vim.uv.fs_rename(current_file, new_file)
      if not ok then
        Snacks.notify.error(('Failed to move %s to %s: %s'):format(current_file, new_file, err))
        return
      end

      vim.cmd('e ' .. vim.fn.fnameescape(new_file))
      vim.api.nvim_buf_delete(original_buffer, { force = true })
    end,
  })
end

M.open_dir_in_explorer = function()
  local dirs = get_local_directories_for_snacks()
  Snacks.picker.pick({
    title = 'open dir in explorer',
    items = dirs,
    confirm = function(picker, item)
      picker:close()

      local destination = item.text
      if not destination then
        return
      end

      Snacks.explorer.open({
        cwd = destination,
      })
    end,
  })
end

M.rm = function()
  os.remove(vim.fn.expand('%'))
  vim.api.nvim_feedkeys(keys.termcodes(':bdelete<cr>'), 'n', true)
end

M.is_current_buffer_a_file = function()
  return vim.fn.expand('%'):match('/')
end

---Filename under the cursor, tolerant of spaces in the path
---(e.g. `example/1 file.txt`). Plain `expand('<cfile>')` stops at whitespace,
---so instead grow candidate substrings around the cursor, longest first, and
---return the first that exists on disk; fall back to '<cfile>' otherwise.
---@return string
local function cfile()
  local fallback = vim.fn.expand('<cfile>')
  if fallback == '' then
    return ''
  end

  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2] + 1 ---@type integer
  for len = #line, 1, -1 do
    for start = math.max(1, col - len + 1), math.min(col, #line - len + 1) do
      local candidate = vim.trim(line:sub(start, start + len - 1))
      -- length check rejects candidates that were trimmed at either end
      if #candidate == len and vim.fn.filereadable(candidate) == 1 then
        return candidate
      end
    end
  end
  return fallback
end

---A window in `tab` that a file may be edited in, best first: one that
---already shows it, else the tab's current window, else its first other
---window — sidebars, terminals and floats skipped, so `:edit` never replaces
---one. Returns nil when the tab has no normal window at all.
---@param tab integer tabpage id
---@param path string absolute path
---@return integer? winid
local function edit_window(tab, path)
  local wins = vim.api.nvim_tabpage_list_wins(tab)
  for _, win in ipairs(wins) do
    if vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(win)) == path then
      return win
    end
  end

  local function editable(win)
    return vim.api.nvim_win_get_config(win).relative == '' and vim.bo[vim.api.nvim_win_get_buf(win)].buftype == ''
  end
  local current = vim.api.nvim_tabpage_get_win(tab)
  if editable(current) then
    return current
  end
  for _, win in ipairs(wins) do
    if editable(win) then
      return win
    end
  end
  return nil
end

---Edit `path` in `win`, landing on `lnum` when given (centred, clamped to the
---file's length so a diff line past its end still opens it).
---@param win integer
---@param path string absolute path
---@param lnum integer?
local function edit_at(win, path, lnum)
  vim.api.nvim_set_current_win(win)
  if vim.api.nvim_buf_get_name(0) ~= path then
    vim.cmd('edit ' .. vim.fn.fnameescape(path))
  end
  if lnum then
    local last = vim.api.nvim_buf_line_count(0)
    vim.api.nvim_win_set_cursor(0, { math.min(math.max(lnum, 1), last), 0 })
    vim.cmd('normal! zz')
  end
end

---Open a file in the first tab -- the working tab, where the code is (the
---tabline marks it with the code icon); tooling that lives in a tab of its own
---(`:Diff`, lazygit, terminals) sends files back there rather than opening
---them inside its own layout.
---@param path string file to open; resolved to a full path
---@param lnum? integer 1-based line to land on, centred (`zz`); clamped to the
---  file's length, so a diff line past its end still opens it
M.open_in_first_tab = function(path, lnum)
  path = vim.fn.fnamemodify(path, ':p')
  local tab = vim.api.nvim_list_tabpages()[1]
  local win = edit_window(tab, path) or vim.api.nvim_tabpage_get_win(tab)
  vim.api.nvim_set_current_tabpage(tab)
  edit_at(win, path, lnum)
end

---Open a file beside the current one, when the current tab has a normal window
---other than the one the cursor is in — fugitive's `:Git show` / `:Git diff`
---open as a split next to the code, so `gf` edits that window rather than
---jumping to another tab. Returns false when the tab has no such window (a
---dedicated `:Diff` tab's only siblings are the DiffTree sidebar and the patch
---buffer itself), so the caller can fall back to the first tab.
---@param path string file to open; resolved to a full path
---@param lnum? integer 1-based line to land on, centred (`zz`)
---@return boolean opened
M.open_in_current_tab = function(path, lnum)
  path = vim.fn.fnamemodify(path, ':p')
  local win = edit_window(vim.api.nvim_get_current_tabpage(), path)
  if not win or win == vim.api.nvim_get_current_win() then
    return false
  end
  edit_at(win, path, lnum)
  return true
end

---Open the file under the cursor at a specific location.
---@param location? 'top_split' | 'first_tab'
M.open_file_in = function(location)
  local file = cfile()
  if file == '' then
    return
  end

  if location == 'first_tab' then
    M.open_in_first_tab(file)
    return
  end

  if location == 'top_split' then
    vim.cmd('wincmd k')
  end

  vim.cmd('edit ' .. vim.fn.fnameescape(file))
end

return M
