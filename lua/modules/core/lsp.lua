return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = { vuels = {} },
      diagnostics = {
        virtual_text = false,
        float = { border = "rounded", source = true },
      },
    },
  },
}
