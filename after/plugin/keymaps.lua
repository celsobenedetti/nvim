local lib = {
  org = require('lib.orgmode'),
  grep = require('lib.grep'),
  cwd = require('lib.cwd'),
}

local function should_write()
  return vim.bo.buftype ~= 'nofile'
    and vim.bo.buftype ~= 'nowrite'
    and vim.bo.buftype ~= 'terminal'
    and vim.fn.expand('%:p') ~= ''
end

-- Save file
map({ 'x', 'n', 'i', 's' }, '<C-s>', function()
  if should_write() then
    vim.cmd('silent w')
  end
  vim.api.nvim_feedkeys(Keys('<esc>'), 'n', false)
end, { desc = 'Save File' })
map('n', '<C-c>', function()
  if should_write() then
    vim.cmd('silent w')
  end
  vim.cmd('q')
end, { desc = 'C-c: write and quit' })

-- lazy
map('n', '<leader>la', '<cmd>Lazy<cr>', { desc = 'Lazy' })

-- tabs
map({ 'n', 't', 'i' }, ']<tab>', function()
  vim.cmd('tabnext')
end, { desc = 'tab: next' })
map({ 'n', 't', 'i' }, '[<tab>', function()
  vim.cmd('tabprevious')
end, { desc = 'tab: previous' })

-- better j/k
local jump = require('lib.jump')
map('n', 'k', jump.up)
map('n', 'j', jump.down)

-- h/l with folding
local fold = require('lib.fold')
map('n', 'h', fold.h, { desc = 'h: move left or fold' })
map('n', 'l', fold.l, { desc = 'l: move right and unfold' })

map('n', '<leader>R', function()
  vim.cmd(':w')
  vim.cmd(':e! %')
  vim.cmd('norm zz')
end, { desc = 'write and refresh buffer' })

-- fs
local fs = require('lib.fs')
map('n', '<leader>mv', fs.mv_file, { desc = 'snacks: move file of current buffer to dir' })
map('n', '<leader>fd', fs.open_dir_in_explorer, { desc = 'snacks: open dir in explorer' })

map({ 'i', 'n', 's' }, '<esc>', function()
  vim.cmd('noh')
  return '<esc>'
end, { expr = true, desc = 'Escape and Clear hlsearch' })

map('n', 'gy', function()
  local file = vim.fn.expand('%:p')
  file = file:gsub(' ', '\\ ')
  vim.fn.setreg('+', file)
  Snacks.notify.info(string.format('Yanked:\n- `%s`', file), {
    title = 'Clipboard',
    icon = '',
    style = 'fancy',
  })
end, { desc = 'Copy file path to clipboard' })

map('v', 'gy', function()
  local file = vim.fn.expand('%:.')
  file = file:gsub(' ', '\\ ')
  local start_line = vim.fn.line('v')
  local end_line = vim.fn.line('.')
  if start_line > end_line then
    start_line, end_line = end_line, start_line
  end
  local text = string.format('%s:%d:%d', file, start_line, end_line)
  vim.fn.setreg('+', text)
  Snacks.notify.info(string.format('Yanked:\n- `%s`', text), {
    title = 'Clipboard',
    icon = '',
    style = 'fancy',
  })
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, false, true), 'n', false)
end, { desc = 'Copy file path:line:line to clipboard' })

map({ 'n', 'x', 'v' }, '<leader>sw', function()
  Snacks.picker.grep_word({ layout = 'ivy_split' })
end, { desc = 'Visual selection or word (Root Dir)' })
map({ 'n', 'x', 'v' }, '<leader>sW', function()
  Snacks.picker.grep_word({ root = false })
end, { desc = 'Visual selection or word (Root Dir)' })

-- gx
local gx = require('lib.gx')
vim.keymap.set('n', 'gx', gx.normal, { desc = 'gx: open link' })
vim.keymap.set('v', 'gx', gx.visual, { desc = 'gx: open link' })

-- orgmode
vim.keymap.set('n', '<leader>in', ':e' .. vim.g.env.org.INBOX .. '<cr>', { desc = 'org: refile file' })
vim.keymap.set('n', '<leader>om', ':e' .. vim.g.env.org.MAIN .. '<cr>', { desc = 'org: main file' })
vim.keymap.set('n', '<leader>ow', ':e' .. vim.g.env.org.WORK .. '<cr>', { desc = 'org: work file' })

vim.keymap.set('n', 'ZZ', function()
  Snacks.notify.warn("Please don't use ZZ")
end, { silent = true, desc = 'Disable ZZ' })

vim.keymap.set('n', '<leader>gn', lib.org.goto_current_task, { desc = 'org: goto current task' })

vim.keymap.set('n', vim.g.key.ghostty['<C-;>'], function()
  vim.ui.input({ prompt = 'run command in new tab: ' }, function(input)
    if not input or #input == 0 then
      return
    end

    local tabname = input
    Snacks.notify.info(tabname)
    if tabname:find('gh') ~= nil then
      tabname = ' ' .. tabname
    end

    vim.cmd.tabnew()
    vim.cmd.term(input)
    vim.g.fn.rename_tab(tabname)
  end)
end, { desc = 'Open terminal in new tab' })

vim.keymap.set('n', vim.g.key['<C-S-g>'], function()
  local cwd = lib.cwd.cwd()
  lib.grep.pick({
    cmd = {
      'rg',
      '--no-heading',
      '--line-number',
      '.',
      cwd,
    },
    cwd = cwd,
  })
end, { desc = 'rg current dir' })
