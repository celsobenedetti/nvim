vim.lsp.enable({
  'eslint',
  'gopls',
  'jsonls',
  'lua_ls',
  'tailwindcss',
  'vtsls',
  'vue_ls',
})

vim.diagnostic.config({
  virtual_lines = false,
  float = {
    source = true,
  },
  signs = {
    active = true,
  },
})

-- setup keymaps
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('lsp-attach', { clear = true }),
  callback = function(event)
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

    map('n', '<leader>cd', vim.diagnostic.open_float, { desc = 'LSP: Line Diagnostics' })
    map('n', ']d', diagnostic_goto(true), { desc = 'LSP: Next Diagnostic' })
    map('n', '[d', diagnostic_goto(false), { desc = 'LSP: Prev Diagnostic' })
    map('n', ']e', diagnostic_goto(true, 'ERROR'), { desc = 'LSP: Next Error' })
    map('n', '[e', diagnostic_goto(false, 'ERROR'), { desc = 'LSP: Prev Error' })
    map('n', ']w', diagnostic_goto(true, 'WARN'), { desc = 'LSP: Next Warning' })
    map('n', '[w', diagnostic_goto(false, 'WARN'), { desc = 'LSP: Prev Warning' })

    map('n', 'gi', vim.lsp.buf.implementation, { desc = 'LSP: Goto Implementation' })
    map('n', 'gd', vim.lsp.buf.definition, { desc = 'LSP: Goto Definition' })
    map('n', 'gD', vim.lsp.buf.declaration, { desc = 'LSP: Goto Declaration' })
    map('i', '<C-k>', vim.lsp.buf.signature_help, { desc = 'LSP: insert mode signature help' })

    map('n', 'gv', function()
      vim.api.nvim_feedkeys(Keys('<c-w>v'), 'n', true)
      vim.schedule(vim.lsp.buf.definition)
      -- Snacks.picker.lsp_definitions()
    end, { desc = 'Split vertical and go to definition' })
  end,
})
