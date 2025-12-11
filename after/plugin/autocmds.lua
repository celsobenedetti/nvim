local autocmd = vim.api.nvim_create_autocmd
local function augroup(name)
  return vim.api.nvim_create_augroup('celso_' .. name, { clear = true })
end

-- Highlight on yank
autocmd('TextYankPost', {
  group = augroup('highlight_yank'),
  callback = function()
    (vim.hl or vim.highlight).on_yank()
  end,
})

-- close some filetypes with <q>
autocmd('FileType', {
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

-- Macros
local macros = augroup('macros')
autocmd('RecordingEnter', {
  group = macros,
  callback = function()
    Snacks.notify.warn('started recording', { title = 'Macro' })
  end,
})
autocmd('RecordingLeave', {
  group = macros,
  callback = function()
    Snacks.notify.info('recording done ✔️', { tlte = 'Macro' })
  end,
})

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
