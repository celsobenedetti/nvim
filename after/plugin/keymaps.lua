local should_quit = function()
  if not lib.term.is_term() then
    return true
  end

  if not lib.term.terminal_is_available() then
    Snacks.notify.warn('Terminal is busy, not quitting')
    return false
  end

  return true
end

local function should_write()
  return vim.bo.buftype ~= 'nofile'
    and vim.bo.buftype ~= 'nowrite'
    and vim.bo.buftype ~= 'terminal'
    and vim.bo.buftype ~= 'help'
    and vim.fn.expand('%:p') ~= ''
end

-- keymap: C-s Save file
vim.keymap.set(
  {
    'x',
    'n',
    -- 'i',
    's',
  },
  '<C-s>',
  function()
    if should_write() then
      vim.cmd('silent w!')
    end
    vim.api.nvim_feedkeys(lib.keys.termcodes('<esc>'), 'n', false)
  end,
  { desc = 'Save File' }
)

vim.keymap.set('n', '<C-c>', function()
  if should_write() then
    vim.cmd('silent w')
  end
  if should_quit() then
    vim.cmd('q')
  end
end, { desc = 'C-c: write and quit' })

-- lazy
vim.keymap.set('n', '<leader>la', '<cmd>Lazy<cr>', { desc = 'Lazy' })

vim.keymap.set({ 'n', 't', 'i' }, config.keys['<C-tab>'], function()
  vim.cmd('tabnext')
end, { desc = 'tab: next (ctrl)' })
vim.keymap.set({ 'n', 't', 'i' }, config.keys['<C-S-tab>'], function()
  vim.cmd('tabprevious')
end, { desc = 'tab: previous (ctrl)' })

vim.keymap.set('c', '', '', { desc = 'cmd: edit in prompt (similar behavior to <C-f>)' })
vim.keymap.set('c', '<C-p>', '<Up>', { desc = 'cmd: previous command' })
vim.keymap.set('c', '<C-n>', '<Down>', { desc = 'cmd: next command' })

-- better j/k
local jump = lib.jump
vim.keymap.set('n', 'k', jump.up)
vim.keymap.set('n', 'j', jump.down)

-- h/l with folding
local fold = lib.fold
vim.keymap.set('n', 'h', fold.h, { desc = 'h: move left or fold' })
vim.keymap.set('n', 'l', fold.l, { desc = 'l: move right and unfold' })

vim.keymap.set('n', '<leader>R', function()
  local fname = vim.fn.expand('%:p')
  if fname == '' then
    return
  end
  local disk_mtime = vim.fn.getftime(fname)
  if disk_mtime <= (vim.b._file_mtime or 0) then
    vim.cmd(':w')
    vim.cmd('norm zz')
  end
end, { desc = 'write buffer if not outdated' })

-- fs
local fs = lib.fs
vim.keymap.set('n', '<leader>mv', fs.mv_file, { desc = 'snacks: move file of current buffer to dir' })
vim.keymap.set('n', '<leader>fd', fs.open_dir_in_explorer, { desc = 'snacks: open dir in explorer' })

vim.keymap.set({ 'i', 'n', 't', 's' }, '<esc>', function()
  vim.cmd('noh')
  lib.cmdline.clear()
  return '<esc>'
end, { expr = true, desc = 'Escape and Clear hlsearch' })

vim.keymap.set('n', 'gy', function()
  local file = vim.fn.expand('%:p')
  file = file:gsub(' ', '\\ ')
  file = file:gsub('oil://', '')
  vim.fn.setreg('+', file)
  Snacks.notify.info(string.format('Yanked:\n- `%s`', file), {
    title = 'Clipboard',
    icon = '',
    style = 'fancy',
  })
end, { desc = 'Copy file path to clipboard' })

vim.keymap.set('v', 'gy', function()
  local file = vim.fn.expand('%:.')
  file = file:gsub(' ', '\\ ')
  local start_line = vim.fn.line('v')
  local end_line = vim.fn.line('.')
  if start_line > end_line then
    start_line, end_line = end_line, start_line
  end
  local text = string.format('%s:%d:%d', file, start_line, end_line)
  vim.fn.setreg('+', text)
  Snacks.notify.info(string.format('Yanked:\n- `%s`', text), { title = 'Clipboard', icon = '', style = 'fancy' })
  vim.api.nvim_input('<Esc>')
end, { desc = 'Copy file path:line:line to clipboard' })

local function grep_word()
  local fzf = require('fzf-lua')
  local mode = vim.fn.mode()
  if mode == 'v' or mode == 'V' or mode == '\22' then
    fzf.grep_visual()
  else
    fzf.grep_cword()
  end
end
vim.keymap.set({ 'n', 'x', 'v' }, '<leader>sw', grep_word, { desc = 'fzf: Visual selection or word' })
vim.keymap.set({ 'n', 'x', 'v' }, '<leader>sW', grep_word, { desc = 'fzf: Visual selection or word' })

-- gx
local gx = lib.gx
vim.keymap.set('n', 'gx', gx.normal, { desc = 'gx: open link' })
vim.keymap.set('v', 'gx', gx.visual, { desc = 'gx: open link' })

-- orgmode
vim.keymap.set('n', '<leader>in', function()
  lib.notes.focus_or_create_notes_tab(function()
    vim.cmd.e(config.org.inbox)
  end)
end, { desc = 'org: refile file' })
-- vim.keymap.set('n', '<leader>oo', ':e' .. config.org.MAIN .. '<cr>', { desc = 'org: actions file' })
vim.keymap.set('n', '<leader>ow', ':e' .. config.org.work .. '<cr>', { desc = 'org: work file' })
vim.keymap.set('n', '<leader>occ', ':Org capture c<cr>', { desc = 'org: capture c' })

vim.keymap.set('n', 'ZZ', function()
  Snacks.notify.warn("Please don't use ZZ")
end, { silent = true, desc = 'Disable ZZ' })

-- Insert mode: Ctrl+B to go back one character (shell-like behavior)
vim.keymap.set('i', '<C-b>', '<Left>', { desc = 'Move back one char (shell-like)' })

vim.keymap.set('n', config.keys['<C-S-g>'], function()
  local cwd = lib.cwd.cwd()
  local cmd = { 'rg' }
  vim.list_extend(cmd, config.cmd.rg.ignore)
  for _, pat in ipairs(config.cmd.rg.exclude_lines) do
    vim.list_extend(cmd, { '-v', pat })
  end
  vim.list_extend(cmd, { cwd })

  lib.fzf.grep({ cmd = cmd, cwd = cwd })
end, { desc = 'rg current dir' })

vim.keymap.set('n', '<leader>rg', function()
  require('fzf-lua').live_grep()
end)

vim.keymap.set('n', '<leader>hh', function()
  vim.cmd.tabnew()
  vim.cmd.term('hunk diff dev...HEAD')
  lib.tab.rename(' hunk')
end)

vim.api.nvim_create_autocmd('FileType', {
  pattern = config.filetypes.gf_open_in_top_split,
  -- augroup = vim.api.nvim_create_augroup('keymap:gf:open-file-in-top-split', { clear = true }),
  callback = function()
    vim.api.nvim_buf_set_keymap(0, 'n', 'gf', ':lua lib.fs.open_file_in("top_split")<CR>', {
      desc = 'terminal: open file in top split',
    })
  end,
  desc = 'Set gf keymap: open file in top split',
})
