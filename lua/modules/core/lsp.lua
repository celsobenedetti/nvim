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
    end,
  },
}
