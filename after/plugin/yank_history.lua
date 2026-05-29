local M = {}

local history = {}
local max_entries = 100
local augroup = vim.api.nvim_create_augroup('yank_history', { clear = true })

vim.api.nvim_create_autocmd('TextYankPost', {
  group = augroup,
  callback = function()
    if vim.v.event.operator ~= 'y' then
      return
    end
    local regname = vim.v.event.regname or '"'
    local value = vim.fn.getreg(regname)
    if value == '' then
      return
    end
    if #history > 0 and history[#history].value == value then
      return
    end
    table.insert(history, {
      value = value,
      regtype = vim.v.event.regtype,
      regname = regname,
      time = os.time(),
    })
    if #history > max_entries then
      table.remove(history, 1)
    end
  end,
})

function M.open()
  if #history == 0 then
    vim.notify('No yank history')
    return
  end
  local items = {}
  for i = #history, 1, -1 do
    local entry = history[i]
    local display = entry.value:gsub('\n', '\\n')
    if #display > 100 then
      display = display:sub(1, 100) .. '...'
    end
    table.insert(items, {
      text = display,
      value = entry.value,
      regtype = entry.regtype,
    })
  end
  Snacks.picker.pick({
    source = 'Yank History',
    layout = 'select',
    items = items,
    format = 'text',
    confirm = function(picker, item)
      vim.fn.setreg('"', item.value, item.regtype)
      picker:close()
    end,
  })
end

vim.api.nvim_create_user_command('YankHistory', M.open, {})

vim.keymap.set('n', '<leader>sy', M.open, { desc = 'yank history' })
