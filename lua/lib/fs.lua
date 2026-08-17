local cwd = lib.cwd
local strings = lib.strings
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

      destination = strings.shellescape(destination)
      local current_file = strings.shellescape(vim.fn.expand('%'))

      vim.cmd('silent! !mv ' .. current_file .. ' ' .. destination)
      local new_file = strings.shellescape((vim.fn.expand('%:t')))

      vim.cmd('e ' .. destination .. '/' .. new_file)
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

---Open the file under the cursor at a specific location.
---@param location? 'top_split'|'first_tab'
M.open_file_in = function(location)
  local file = vim.fn.expand('<cfile>')
  if file == '' then
    return
  end

  if location == 'top_split' then
    vim.cmd('wincmd k')
  elseif location == 'first_tab' then
    vim.cmd('tabfirst')
  end

  vim.cmd('edit ' .. vim.fn.fnameescape(file))
end

return M
