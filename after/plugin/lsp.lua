if not state.lsp then
  return
end

vim.lsp.enable({
  'bashls',
  'denols',
  -- 'copilot',
  -- 'eslint',
  'gopls',
  'jsonls',
  -- 'harper_ls',
  'lua_ls',
  'org',
  'pyright',
  'tsc',
  -- 'tailwindcss',
  'tinymist',
  -- 'vtsls',
  'vue_ls',
})

vim.diagnostic.config({
  virtual_lines = false,
  virtual_text = { prefix = '●', severity = vim.diagnostic.severity.ERROR },
  float = {
    source = true,
  },
  signs = {
    active = true,
    text = {
      [vim.diagnostic.severity.ERROR] = config.icons.diagnostics.error,
      [vim.diagnostic.severity.WARN] = config.icons.diagnostics.warn,
      [vim.diagnostic.severity.INFO] = config.icons.diagnostics.info,
      [vim.diagnostic.severity.HINT] = config.icons.diagnostics.hint,
    },
  },
})

-- setup keymaps
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('lsp-attach', { clear = true }),
  callback = function(event)
    -- map('n', 'gi', vim.lsp.buf.implementation, { desc = 'LSP: Goto Implementation' }) -- NOTE: let's use default gri instead
    vim.keymap.set('n', 'gd', vim.lsp.buf.definition, { desc = 'LSP: Goto Definition' })
    vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, { desc = 'LSP: Goto Declaration' })
    vim.keymap.set('i', '<C-k>', vim.lsp.buf.signature_help, { desc = 'LSP: insert mode signature help' })
  end,
})

-- keymaps for diagnostics should be applied for nvim-lint, event if no lsp is attached
local diagnostic_goto = function(next, severity)
  severity = severity and vim.diagnostic.severity[severity] or nil
  return function()
    vim.diagnostic.jump({
      severity = severity,
      count = next and 1 or -1,
      float = true,
    })
  end
end

vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, { desc = 'LSP: Line Diagnostics' })
vim.keymap.set('n', ']d', diagnostic_goto(true), { desc = 'LSP: Next Diagnostic' })
vim.keymap.set('n', '[d', diagnostic_goto(false), { desc = 'LSP: Prev Diagnostic' })
vim.keymap.set('n', ']e', diagnostic_goto(true, 'ERROR'), { desc = 'LSP: Next Error' })
vim.keymap.set('n', '[e', diagnostic_goto(false, 'ERROR'), { desc = 'LSP: Prev Error' })
vim.keymap.set('n', ']w', diagnostic_goto(true, 'WARN'), { desc = 'LSP: Next Warning' })
vim.keymap.set('n', '[w', diagnostic_goto(false, 'WARN'), { desc = 'LSP: Prev Warning' })
