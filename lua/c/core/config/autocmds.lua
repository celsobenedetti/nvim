local all = vim.api.nvim_create_augroup('AllFilesGroup', { clear = true })
local markdown = vim.api.nvim_create_augroup('MarkdownGroup', { clear = true })
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

-- Markdown --------------------------------------------------------------

if markdown then
  vim.api.nvim_create_autocmd({ 'VimEnter' }, {
    pattern = '*.md',
    callback = function()
      vim.api.nvim_feedkeys(Keys '/#<CR>', 'n', true)
      vim.api.nvim_feedkeys(Keys ':nohlsearch<CR>', 'n', true)

      require('twilight').enable()

      -- NOTE: for some reason catpuccin loads differently if not set in autocmd
      vim.cmd.colorscheme 'catppuccin-mocha'
    end,
    group = markdown,
    desc = 'Run when entering vim in Markdown file',
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
vim.api.nvim_create_autocmd('FileType', {
  group = augroup 'git-commit-augroup',
  pattern = { 'gitcommit' },
  callback = function()
    vim.api.nvim_feedkeys(Keys 'i<BS>', 'n', true)
  end,
})
