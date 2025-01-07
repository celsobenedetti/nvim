return {
  {
    'SmiteshP/nvim-navic',
    lazy = true,
    init = function()
      if C.global.performance then
        return
      end

      vim.g.navic_silence = true
      C.lsp.on_attach(function(client, buffer)
        if client.supports_method 'textDocument/documentSymbol' then
          require('nvim-navic').attach(client, buffer)
        end
      end)
    end,
    opts = function()
      return {
        separator = ' ',
        highlight = false,
        depth_limit = 5,
        icons = C.UI.icons.kinds,
        lazy_update_context = true,
      }
    end,
  },

  {
    'nvim-lualine/lualine.nvim',
    optional = true,
    opts = function(_, opts)
      if not vim.g.trouble_lualine then
        table.insert(opts.sections.lualine_c, {
          'navic',
          -- nil or 'static' seem to work here
          color_correction = nil,
        })
      end
    end,
  },
}
