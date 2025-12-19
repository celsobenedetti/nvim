local function augroup(name)
  return vim.api.nvim_create_augroup('celso_' .. name, { clear = true })
end

-- Highlight on yank
vim.api.nvim_create_autocmd('TextYankPost', {
  group = augroup('highlight_yank'),
  callback = function()
    (vim.hl or vim.highlight).on_yank()
  end,
})

-- close some filetypes with <q>
vim.api.nvim_create_autocmd('FileType', {
  group = augroup('close_with_q'),
  pattern = vim.g.close_with_q,
  callback = function(event)
    vim.bo[event.buf].buflisted = false
    vim.schedule(function()
      vim.keymap.set('n', 'q', function()
        vim.cmd('close')
        pcall(vim.api.nvim_buf_delete, event.buf, { force = true })
      end, {
        buffer = event.buf,
        silent = true,
        desc = 'Quit buffer',
      })
    end)
  end,
})

-- stylua: ignore start
local macros = augroup('macros')
vim.api.nvim_create_autocmd('RecordingEnter', { group = macros, callback = function() vim.g.recording_macro = true end, })
vim.api.nvim_create_autocmd('RecordingLeave', { group = macros, callback = function() vim.g.recording_macro = false end, })
-- stylua: ignore end

-- open file in same position it was last closed
-- https://stackoverflow.com/questions/72826129/in-neovim-how-do-i-get-a-file-to-open-at-the-same-line-number-i-closed-it-at-la#72836352
vim.api.nvim_create_autocmd('BufReadPost', {
  pattern = { '*' },
  callback = function()
    if vim.fn.line('\'"') > 1 and vim.fn.line('\'"') <= vim.fn.line('$') then
      vim.cmd('normal! g\'"')
    end
  end,
})

-- -- diosable comment continuation on different lines
-- -- https://neovim.discourse.group/t/how-do-i-prevent-neovim-commenting-out-next-line-after-a-comment-line/3711/7
-- vim.api.nvim_create_autocmd('FileType', {
--   pattern = '*',
--   callback = function()
--     vim.opt_local.formatoptions:remove({ 'r', 'o' })
--   end,
-- })
