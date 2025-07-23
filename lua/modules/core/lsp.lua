return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = { volar = {} },
      diagnostics = {
        virtual_text = false,
        float = { border = "rounded", source = true },
      },
    },
  },
}
