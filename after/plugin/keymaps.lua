-- Save file
map({ 'x', 'n', 'i', 's' }, '<C-s>', '<cmd>silent w<cr><esc>', { desc = 'Save File' })

map('n', '<C-c>', function()
  local file = vim.fn.expand('%:p')
  if vim.bo.buftype ~= 'nofile' and file and file ~= '' then
    vim.cmd('silent w')
  end
  vim.cmd('q')
end, { desc = 'C-c: write and quit' })

-- lazy
map('n', '<leader>la', '<cmd>Lazy<cr>', { desc = 'Lazy' })

-- tabs
map('n', ']<tab>', ':tabnext<CR>', { desc = 'tab: next' })
map('n', '[<tab>', ':tabprevious<CR>', { desc = 'tab: prev' })

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

map('n', 'gA', function()
  local cmd = string.format('git add -p %s', vim.fn.expand('%'))
  require('lib.tmux').neww(cmd)
end, {
  desc = 'tmux: neww `add.sh %`',
})
map('n', 'gC', function()
  require('lib.tmux').neww('commit.sh')
end, {
  desc = 'tmux: neww `commit.sh`',
})

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

vim.keymap.set('n', 'NOTES', function()
  require('lib.notes').focus_or_create_notes_tab(function()
    require('lib.git_grep_notes').git_grep_notes({
      cwd = vim.g.env.notes.NOTES,
      cmd = {
        'rg',
        '--no-heading',
        '--line-number',
        '-g',
        '!' .. vim.g.env.notes.ASSETS_DIR .. '/*',
        '-v',
        vim.g.env.notes.GREP_IGNORE, -- No quotes needed here!
        vim.g.env.notes.NOTES,
      },
    })
  end)
end, { desc = 'search all notes' })

-- orgmode
vim.keymap.set('n', '<leader>in', ':e' .. vim.g.env.org.INBOX .. '<cr>', { desc = 'org: refile file' })
vim.keymap.set('n', '<leader>om', ':e' .. vim.g.env.org.MAIN .. '<cr>', { desc = 'org: main file' })
vim.keymap.set('n', '<leader>ow', ':e' .. vim.g.env.org.WORK .. '<cr>', { desc = 'org: work file' })

vim.keymap.set('n', 'ZZ', function()
  Snacks.notify.warn("Please don't use ZZ")
end, { silent = true, desc = 'Disable ZZ' })
