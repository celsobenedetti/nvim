return {
  {
    'neovim/nvim-lspconfig',
    opts = function(_, opts)
      local keys = require('lazyvim.plugins.lsp.keymaps').get()

      if vim.g.performance then
        opts.inlay_hints = { enabled = false }
      end

      vim.list_extend(keys, {
        { 'gr', false },
      })

      opts.diagnostics.virtual_text = false
      opts.diagnostics.float = { border = 'rounded', source = true }

      opts.servers.ols = {}

      opts.servers.vtsls.settings.typescript.tsserver =
        vim.tbl_deep_extend('force', opts.servers.vtsls.settings.typescript.tsserver or {}, {
          maxTsServerMemory = 8192,
        })

      opts.servers.vtsls.keys = {
        {
          'gD',
          function()
            local params = vim.lsp.util.make_position_params()
            LazyVim.lsp.execute {
              command = 'typescript.goToSourceDefinition',
              arguments = { params.textDocument.uri, params.position },
              open = true,
            }
          end,
          desc = 'Goto Source Definition',
        },
        {
          'gR',
          function()
            LazyVim.lsp.execute {
              command = 'typescript.findAllFileReferences',
              arguments = { vim.uri_from_bufnr(0) },
              open = true,
            }
          end,
          desc = 'File References',
        },
        {
          '<leader>oi',
          LazyVim.lsp.action['source.organizeImports'],
          desc = 'Organize Imports',
        },
        {
          '<leader>ami',
          LazyVim.lsp.action['source.addMissingImports.ts'],
          desc = 'Add missing imports',
        },
        {
          '<leader>ru',
          LazyVim.lsp.action['source.removeUnused.ts'],
          desc = 'Remove unused imports',
        },
        {
          '<leader>fA',
          LazyVim.lsp.action['source.fixAll.ts'],
          desc = 'Fix all diagnostics',
        },
        {
          '<leader>cV',
          function()
            LazyVim.lsp.execute { command = 'typescript.selectTypeScriptVersion' }
          end,
          desc = 'Select TS workspace version',
        },
      }
    end,
  },
}
