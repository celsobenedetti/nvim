-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

vim.keymap.del('n', '<leader>n')
vim.keymap.del('n', '<leader>e')
-- vim.keymap.del({ 'n', 't' }, '<C-_>')
-- vim.keymap.del({ 'n', 't' }, '<C-/>')

local open = require 'lib.open'
local web = require 'lib.web'
local jump = require 'lib.jump'
local visual = require 'lib.visual'
local keys = require 'lib.keys'
local toggle = require 'lib.toggle'
local runner = require 'lib.runner'

map('x', 'p', '"_dP', { desc = 'Paste without losing register' }) --hold on to register when pasting and replace text
-- map('x', 'ZZ', function()
--   if Snacks.zen.win and Snacks.zen.win.close then
--     -- ZZ
--     vim.cmd ''
--   end
-- end, { desc = 'Paste without losing register' }) --hold on to register when pasting and replace text
map('n', '<leader>R', ':e! %<cr>', { desc = 'Refresh Buffer' })
map('t', '<esc><esc>', '<C-\\><C-n>', { desc = 'Escape insert mode in terminal' }) -- let me escape insert in terminal!
map('n', 'ZQ', ':qa!<CR>', { desc = 'Quit all' })
map('n', '<leader>C', ':Clip<CR>', { desc = 'Copy file path to clipboard' })
map('n', '<leader>mv', require('lib.fs').mv_file, { desc = 'Move file of current buffer to dir' })
map('n', '<leader>tc', toggle.completion, { desc = 'toggle: completion' })
map('n', '<leader><tab><tab>', ':tabnext<CR>', { desc = 'tab: next' })
map('n', '<leader><tab>n', ':tabnew<CR>', { desc = 'tab: new' })
map('n', 'dd', function()
  if vim.bo.filetype == 'qf' then
    require('lib.quickfix').remove_item()
    return
  end
  vim.cmd 'normal! dd'
end, { desc = 'tab: new' })

-- map("n", "<leader>dim", function()
--   Snacks.dim.enable({ scope = { max_size = 1 } })
-- end, { desc = "Mega dim" })

map('v', 'gx', open.omni_open, { desc = 'Search current selected string with google' })
map('v', 'gs', open.omni_open, { desc = 'Search current selected string with google' })

map('n', 'k', jump.up)
map('n', 'j', jump.down)

-- default icc <c-w>d
-- map('n', '<leader>cd', vim.diagnostic.open_float, { desc = 'Line Diagnostics' })
map('n', ']d', jump.diagnostic_goto(true), { desc = 'Next Diagnostic' })
map('n', '[d', jump.diagnostic_goto(false), { desc = 'Prev Diagnostic' })
map('n', ']e', jump.diagnostic_goto(true, 'ERROR'), { desc = 'Next Error' })
map('n', '[e', jump.diagnostic_goto(false, 'ERROR'), { desc = 'Prev Error' })
map('n', ']w', jump.diagnostic_goto(true, 'WARN'), { desc = 'Next Warning' })
map('n', '[w', jump.diagnostic_goto(false, 'WARN'), { desc = 'Prev Warning' })



-- stylua: ignore start 
map("v", "<leader>b", function() visual.wrap("**", "**") end, { desc = "bold: wrap selection with **" })
map("v", "<leader>i", function() visual.wrap("_", "_") end, { desc = "italic: wrap selection with _" })
-- stylua: ignore end

map('n', '<leader>pj', runner.run_package_json_script, { desc = 'run package.json scripts' })
map('n', '<leader>ju', runner.run_justfile_target, { desc = 'run justfile targets' })

if vim.g.should_center.on_n then
  map('n', 'n', keys.with_delay('n', 'zz'), { desc = 'center on next', noremap = true })
  map('n', 'N', keys.with_delay('N', 'zz'), { desc = 'center on prev', noremap = true })
end

if vim.g.should_center.on_gg then
  map('n', 'G', keys.G, { desc = 'center on gg', noremap = true })
end

if vim.g.should_center.on_ctrl_d then
  map('n', '<C-d>', keys.with_delay('<C-d>', 'zz'), { desc = 'center on ctrl-d', noremap = true })
  map('n', '<C-u>', keys.with_delay('<C-u>', 'zz'), { desc = 'center on ctrl-u', noremap = true })
end

map('n', 'gv', function()
  vim.api.nvim_feedkeys(Keys '<c-w>v', 'n', true)
  Snacks.picker.lsp_definitions()
end, { desc = 'Split vertical and go to definition' })

map('n', 'gs', function()
  vim.api.nvim_feedkeys(Keys '<c-w>s', 'n', true)
  Snacks.picker.lsp_definitions()
end, { desc = 'Split vertical and go to definition' })

map('n', '<leader>B', function()
  local conform = require 'conform'
  local line = vim.fn.getline '.'
  local web_query = web.get_search_url_from_query(line)
  if web_query and #web_query > 0 then
    vim.api.nvim_feedkeys('dd', 'n', true)
    vim.ui.open(web_query)
  else
    vim.api.nvim_feedkeys(Keys 'V!bash<CR>', 'n', true)
  end
  vim.defer_fn(conform.format, 500)
end, { desc = 'Run current line as bash command' })

map('v', '<leader>B', function()
  vim.api.nvim_feedkeys(Keys '!bash<CR>', 'n', true)
end, { desc = 'Run current line as bash command' })

map('n', '<leader>P', function()
  vim.api.nvim_feedkeys(Keys 'vip', 'n', true)
  local file_path = vim.fn.expand '%:p'
  if file_path:find 'html' then
    vim.api.nvim_feedkeys(Keys '!prettier --parser=html<CR>', 'n', true)
  else
    vim.api.nvim_feedkeys(Keys '!prettier --parser=markdown<CR>', 'n', true)
  end
end, { desc = 'Format current paragraph with Prettier' })

map('v', '<leader>P', function()
  local file_path = vim.fn.expand '%:p'
  if file_path:find '.md' then
    vim.api.nvim_feedkeys(Keys '!prettier --parser=markdown<CR>', 'n', true)
  else
    vim.api.nvim_feedkeys(Keys '!prettier --parser=html<CR>', 'n', true)
  end
end, { desc = 'Format current selection with Prettier' })

map('n', '<leader>rm', function()
  vim.api.nvim_feedkeys(Keys ':!rm %<CR>', 'n', true)
  vim.api.nvim_feedkeys(Keys ':bdelete<cr>', 'n', true)
end, { desc = 'rm buffer file' })

map('c', '<C-A>', '<Home>', { desc = '<Home>' })
-- map('c', '<C-F>', '<Right>', { desc = '<Right>' })
-- map('c', '<C-B>', '<Left>', { desc = '<Left>' })
map('c', '<Esc>h', '<S-Left>', { desc = '<S-Left>' })
map('c', '<Esc>l', '<S-Right>', { desc = '<S-Right>' })
