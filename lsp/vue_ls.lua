-- https://github.com/neovim/nvim-lspconfig/blob/a2bd1cf7b0446a7414aaf373cea5e4ca804c9c69/lsp/vue_ls.lua
return {
  on_attach = function(client)
    client.server_capabilities.documentFormattingProvider = false
    client.server_capabilities.documentRangeFormattingProvider = false
  end,
}
