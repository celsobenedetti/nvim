local all = vim.api.nvim_create_augroup('AllFilesGroup', { clear = true })
local json = vim.api.nvim_create_augroup('JSONGroup', { clear = true })
local new_note = vim.api.nvim_create_augroup('NewNoteGroup', { clear = true })

-- TODO: refactor remaining autocmds
local function augroup(name)
  return vim.api.nvim_create_augroup('my_autocmd-' .. name, { clear = true })
end

-- All files --------------------------------------------------------------

if all then
  vim.api.nvim_create_autocmd({ 'VimEnter' }, {
    callback = function()
      vim.cmd 'setlocal formatoptions-=cro' -- Stop comment continuation on line below
    end,
    group = all,
    desc = 'Run on all files',
  })
end

-- JSON --------------------------------------------------------------

if json then
  vim.api.nvim_create_autocmd({ 'VimEnter' }, {
    pattern = '*.json',
    callback = function()
      vim.o.conceallevel = 3
    end,
    group = json,
    desc = 'Run when entering JSON files',
  })
end

-- new_note --------------------------------------------------------------

if new_note then
  vim.api.nvim_create_autocmd({ 'VimEnter' }, {
    pattern = 'title_editor',
    callback = function()
      vim.api.nvim_feedkeys(Keys 'ggi<BS><BS><BS>', 'n', true)
    end,
    group = new_note,
    desc = 'Run when entering new_note files',
  })
end

-- wrap and check for spell in text filetypes
vim.api.nvim_create_autocmd('FileType', {
  group = augroup 'wrap_spell',
  pattern = { 'gitcommit', 'markdown' },
  callback = function()
    vim.opt_local.wrap = true
    vim.opt_local.spell = true
  end,
})

-- insert mode when entering git commit
vim.api.nvim_create_autocmd('VimEnter', {
  group = augroup 'git-commit-augroup',
  pattern = { 'COMMIT_EDITMSG' },
  callback = function()
    vim.cmd.colorscheme(vim.g.secondary_color)
    vim.api.nvim_feedkeys(Keys 'i<BS>', 'n', true)
  end,
})
