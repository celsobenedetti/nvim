local autocmd = vim.api.nvim_create_autocmd
local function augroup(name)
  return vim.api.nvim_create_augroup('celso_' .. name, { clear = true })
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

-- Highlight on yank
vim.api.nvim_create_autocmd('TextYankPost', {
  group = augroup 'highlight_yank',
  callback = function()
    (vim.hl or vim.highlight).on_yank()
  end,
})
