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

---Open the file under the cursor at a specific location.
---@param location? 'top_split'
M.open_file_in = function(location)
  local file = cfile()
  if file == '' then
    return
  end

  if location == 'top_split' then
    vim.cmd('wincmd k')
  end

  vim.cmd('edit ' .. vim.fn.fnameescape(file))
end

return M
