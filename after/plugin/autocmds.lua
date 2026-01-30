local function augroup(name)
  return vim.api.nvim_create_augroup('celso_' .. name, { clear = true })
end

--- each autocmd should have its group defined here
local groups = {
  treesitter_highlight = augroup('treesitter_highlight'),
  close_with_q = augroup('close_with_q'),
  restore_position_when_opening_file = augroup('restore_position_when_opening_file'),
  highlight_on_yank = augroup('highlight_on_yank'),
  on_macro = augroup('macros'),
  disable_comment_continuation = augroup('disable_comment_continuation'),
}

-- Highlight on yank
vim.api.nvim_create_autocmd('TextYankPost', {
  group = groups.highlight_on_yank,
  callback = function()
    (vim.hl or vim.highlight).on_yank()
  end,
})

-- Tresitter Highlight
if vim.g.treesitter then
  vim.api.nvim_create_autocmd('FileType', {
    group = groups.treesitter_highlight,
    pattern = vim.g.treesitter.highlight,
    callback = function()
      vim.treesitter.start()
    end,
  })
end

-- close some filetypes with <q>
vim.api.nvim_create_autocmd('FileType', {
  group = groups.close_with_q,
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

-- open file in same position it was last closed
-- https://stackoverflow.com/questions/72826129/in-neovim-how-do-i-get-a-file-to-open-at-the-same-line-number-i-closed-it-at-la#72836352
vim.api.nvim_create_autocmd('BufReadPost', {
  pattern = { '*' },
  group = groups.restore_position_when_opening_file,
  callback = function()
    if vim.fn.line('\'"') > 1 and vim.fn.line('\'"') <= vim.fn.line('$') then
      vim.cmd('normal! g\'"')
    end
  end,
})

-- diosable comment continuation on different lines
-- https://neovim.discourse.group/t/how-do-i-prevent-neovim-commenting-out-next-line-after-a-comment-line/3711/7
if vim.g.disable_comment_continuation then
  vim.api.nvim_create_autocmd('FileType', {
    pattern = '*',
    group = groups.disable_comment_continuation,
    callback = function()
      vim.opt_local.formatoptions:remove({ 'r', 'o' })
    end,
  })
end

-- Macros: notifications when recording starts and stops
vim.api.nvim_create_autocmd('RecordingEnter', {
  group = groups.on_macro,
  callback = function()
    vim.g.recording_macro = true
    Snacks.notify.info(' recording', { title = 'Macro' })
  end,
})
vim.api.nvim_create_autocmd('RecordingLeave', {
  group = groups.on_macro,
  callback = function()
    vim.g.recording_macro = false
    Snacks.notify.info(' done', { title = 'Macro' })
  end,
})
