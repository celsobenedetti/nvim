---@module 'statusline' home cooked statusline plugin
-- Home-cooked tabline: named tabs backed by lib/tab
local tab = require('lib.tab')

-- showtabline = 1: hide the tabline while a single tab is open (like
-- default nvim and tabby.nvim), show it once there are at least two.
vim.o.showtabline = 1
vim.o.tabline = "%!v:lua.require('lib.tab').render()"

vim.api.nvim_create_user_command('TabRename', function(opts)
  tab.rename(opts.args)
end, { nargs = '?' })

local group = vim.api.nvim_create_augroup('homegrown_tabs', { clear = true })
for _, event in ipairs({ 'TabNew', 'TabClosed', 'WinEnter', 'BufEnter', 'BufWinEnter', 'TermOpen' }) do
  vim.api.nvim_create_autocmd(event, {
    group = group,
    callback = function()
      vim.cmd('redrawtabline')
    end,
  })
end

---@module 'TabPicker'
-- https://gist.github.com/cameronr/68b2f9f73b54d72bf992eb4c956f0c13

local function get_tabs()
  local tabs = {}
  local tabpages = vim.api.nvim_list_tabpages()
  for i, tabpage in ipairs(tabpages) do
    local wins = vim.api.nvim_tabpage_list_wins(tabpage)
    local cur_win = vim.api.nvim_tabpage_get_win(tabpage)
    local name = require('lib.tab').get_name(tabpage)
    if name == '' then
      name = '[No Name]'
    end

    local preview_lines = {}
    table.insert(preview_lines, ('Tab %d: %d window%s'):format(i, #wins, #wins == 1 and '' or 's'))
    table.insert(preview_lines, ('%-6s %-8s %s'):format('WinID', 'Buf#', 'File'))
    table.insert(preview_lines, string.rep('-', 40))
    for _, win in ipairs(wins) do
      local win_buf = vim.api.nvim_win_get_buf(win)
      local bufname = vim.api.nvim_buf_get_name(win_buf)
      if bufname == '' then
        bufname = '[No Name]'
      end
      bufname = vim.fn.fnamemodify(bufname, ':~:.') -- relative to cwd, or ~
      local win_marker = (win == cur_win) and '->' or '  '
      table.insert(preview_lines, ('%s %-6d %-8d %s'):format(win_marker, win, win_buf, bufname))
    end
    if #wins == 0 then
      table.insert(preview_lines, 'No windows in tab')
    end

    table.insert(tabs, {
      idx = i,
      text = ('Tab %d: %s'):format(i, name),
      tabnr = i,
      tabpage = tabpage,
      preview = {
        text = table.concat(preview_lines, '\n'),
        ft = 'text',
      },
    })
  end
  return tabs
end

local function tabs_picker()
  local items = get_tabs()
  Snacks.picker({
    title = 'Tabs',
    items = items,
    format = 'text',
    confirm = function(picker, item)
      picker:close()
      vim.cmd(('tabnext %d'):format(item.tabnr))
    end,
    preview = 'preview',
    actions = {
      close_tab = function(picker, item)
        picker:close()
        vim.cmd(('tabclose %d'):format(item.tabnr))
      end,
    },
    win = {
      input = {
        keys = {
          ['d'] = 'close_tab',
        },
      },
    },
  })
end

vim.api.nvim_create_user_command('TabsPicker', function()
  tabs_picker()
end, { nargs = 0 })
