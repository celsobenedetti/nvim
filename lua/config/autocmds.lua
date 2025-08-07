-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

local autocmd = vim.api.nvim_create_autocmd

local function augroup(name)
  return vim.api.nvim_create_augroup('celso_augroup_' .. name, { clear = true })
end

-- insert mode when entering git commit
autocmd('VimEnter', {
  desc = 'Insert mode when entering git commit',
  group = augroup 'Git_Commit_Editor',
  pattern = { 'COMMIT_EDITMSG', 'new_note' },
  callback = function()
    vim.api.nvim_feedkeys(Keys 'i<BS>', 'n', true)
  end,
})

autocmd({ 'VimEnter' }, {
  desc = 'Run on all files',
  callback = function()
    vim.cmd 'set formatoptions-=cro' -- Stop comment continuation on line below
  end,
  group = augroup 'Run_on_VimEnter',
})

-- VimEnter autocmd should fold all
-- BufRead autocmd should fold frontmatter
local markdown_group = augroup 'Markdown'
local markdown = '*.md'
autocmd('VimEnter', {
  desc = 'Fold all headings when entering markdown files',
  pattern = markdown,
  group = markdown_group,
  callback = function()
    -- nested markdown folding
    vim.cmd 'set foldexpr=NestedMarkdownFolds()'

    vim.defer_fn(function()
      -- fold all
      vim.api.nvim_feedkeys(Keys 'zM', 'n', true)

      vim.defer_fn(function()
        -- go do #heading1
        vim.api.nvim_feedkeys(Keys 'G', 'n', true)

        vim.defer_fn(function()
          -- unfold it
          vim.api.nvim_feedkeys(Keys 'zo', 'n', true)
        end, 60)
      end, 60)
    end, 100)
  end,
})

autocmd('BufEnter', {
  desc = 'Fold frontmatter when entering markdown file',
  pattern = markdown,
  group = markdown_group,
  callback = function()
    vim.defer_fn(function()
      require('lib.markdown').fold_frontmatter()
    end, 100)
  end,
})

autocmd({
  'TermOpen',
  'BufWinEnter',
  -- 'WinEnter' this one is too agressive. We want to preserve the cursor position whenever entering a terminal buffer. we may be scrolled up looking at logs, etc.
}, {
  desc = 'Always insert mode when entering a terminal',
  pattern = 'term://*',
  callback = function()
    vim.cmd 'startinsert'
  end,
  group = augroup 'term-enter',
})

if os.getenv 'IS_ZEN' == 'true' then
  require 'lib.startup.zen'
end
