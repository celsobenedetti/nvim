function Augroup(name)
  return vim.api.nvim_create_augroup('Custom_Augroup_' .. name, { clear = true })
end

vim.api.nvim_create_autocmd({ 'VimEnter' }, {
  callback = function()
    vim.cmd 'set formatoptions-=cro' -- Stop comment continuation on line below
  end,
  group = Augroup 'Run_on_VimEnter',
  desc = 'Run on all files',
})

-- Highlight on yank
vim.api.nvim_create_autocmd('TextYankPost', {
  group = Augroup 'highlight_yank',
  callback = function()
    (vim.hl or vim.highlight).on_yank()
  end,
})

--- Used for tmux pane resizing
vim.api.nvim_create_autocmd('VimResized', {
  group = Augroup 'Resize_Windows',
  pattern = '*',
  command = 'wincmd =',
  desc = 'Automatically resize windows when the host window size changes.',
})

-- insert mode when entering git commit
vim.api.nvim_create_autocmd('VimEnter', {
  group = Augroup 'Git_Commit_Editor',
  pattern = { 'COMMIT_EDITMSG', 'new_note' },
  callback = function()
    vim.api.nvim_feedkeys(Keys 'i<BS>', 'n', true)
  end,
})

-- Refresh agenda for orgfiles
vim.api.nvim_create_autocmd('BufWritePost', {
  pattern = '*.org',
  callback = function()
    local bufnr = vim.fn.bufnr 'orgagenda' or -1
    if bufnr > -1 then
      require('orgmode').agenda:redo()
    end
  end,
})

-- -- Code files
-- local code_files_group = Augroup 'Code_Files'
-- local code_files = {
--   '*.lua',
--   '*.go',
--   '*.sh',
--   '*.js',
--   '*.ts',
--   '*.tsx',
--   '*.md',
-- }
-- vim.api.nvim_create_autocmd('BufRead', {
--   pattern = code_files,
--   group = code_files_group,
--   callback = function()
--     // fold
--     vim.api.nvim_feedkeys(Keys 'zM', 'n', true)
--   end,
-- })

-- -- Code files
local markdown_group = Augroup 'Markdown'
local markdown = '*.md'
vim.api.nvim_create_autocmd('VimEnter', {
  pattern = markdown,
  group = markdown_group,
  callback = function()
    -- nested markdown folding
    vim.cmd 'set foldexpr=NestedMarkdownFolds()'

    vim.defer_fn(function()
      require('lib.functions.markdown.fold_frontmatter').run()
    end, 100)

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
