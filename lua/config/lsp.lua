vim.lsp.enable {
  'eslint',
  'jsonls',
  'lua_ls',
  'vtsls',
}

--keymaps
local diagnostic_goto = function(next, severity)
  severity = severity and vim.diagnostic.severity[severity] or nil
  return function()
    vim.diagnostic.jump {
      severity = severity,
      count = next and 1 or -1,
      float = true,
    }
  end
end

vim.keymap.set('n', '<leader>cd', vim.diagnostic.open_float, { desc = 'Line Diagnostics' })
vim.keymap.set('n', ']d', diagnostic_goto(true), { desc = 'Next Diagnostic' })
vim.keymap.set('n', '[d', diagnostic_goto(false), { desc = 'Prev Diagnostic' })
vim.keymap.set('n', ']e', diagnostic_goto(true, 'ERROR'), { desc = 'Next Error' })
vim.keymap.set('n', '[e', diagnostic_goto(false, 'ERROR'), { desc = 'Prev Error' })
vim.keymap.set('n', ']w', diagnostic_goto(true, 'WARN'), { desc = 'Next Warning' })
vim.keymap.set('n', '[w', diagnostic_goto(false, 'WARN'), { desc = 'Prev Warning' })

vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, { desc = 'Goto Implementation' })
vim.keymap.set('n', 'gd', vim.lsp.buf.definition, { desc = 'Goto Definition' })
vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, { desc = 'Goto Declaration' })

map('n', 'gv', function()
  vim.api.nvim_feedkeys(Keys '<c-w>v', 'n', true)
  vim.lsp.buf.definition()
  -- Snacks.picker.lsp_definitions()
end, { desc = 'Split vertical and go to definition' })
