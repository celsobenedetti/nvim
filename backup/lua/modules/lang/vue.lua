return {
  'neovim/nvim-lspconfig',
  opts = function(_, opts)
    if not require('lib.cwd').find_file 'vite.config.ts' then
      -- not a vue project, let's dip
      return
    end

    opts.servers.vtsls = opts.servers.vtsls or {}
    opts.servers.vtsls.filetypes = opts.servers.vtsls.filetypes or {}
    table.insert(opts.servers.vtsls.filetypes, 'vue')

    opts.servers.vue_ls = { -- when LazyVim switches to nvim-lspconfig ≥ v2.2.0 rename this to `vue_ls`
      on_attach = function(client)
        client.server_capabilities.documentFormattingProvider = false
        client.server_capabilities.documentRangeFormattingProvider = false
      end,
    }
  end,
}
