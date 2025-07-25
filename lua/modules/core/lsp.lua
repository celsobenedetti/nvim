return {
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      opts.diagnostics.virtual_text = false
      opts.diagnostics.float = { border = "rounded", source = true }

      opts.servers.vtsls.settings.typescript.tsserver =
        vim.tbl_deep_extend("force", opts.servers.vtsls.settings.typescript.tsserver or {}, {
          maxTsServerMemory = 8192,
        })
    end,
  },
}
