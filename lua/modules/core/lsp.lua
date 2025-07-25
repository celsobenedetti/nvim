return {
  {
    "neovim/nvim-lspconfig",
    keys = {
      { "[[", false },
      { "]]", false },
    },
    opts = function(_, opts)
      opts.diagnostics.virtual_text = false
      opts.diagnostics.float = { border = "rounded", source = true }

      opts.servers = {
        vtsls = {
          settings = {
            typescript = {
              tsserver = {
                maxTsServerMemory = 8192,
              },
            },
          },
        },
      }
    end,
  },
}
