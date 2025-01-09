return {
  {
    'SmiteshP/nvim-navic',
    lazy = true,
    init = function()
      if C.opt.performance then
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

  -- TODO:  add either this or lualine to top
  {
    'nvim-lualine/lualine.nvim',
    optional = true,
    opts = function(_, opts)
      local root = vim.fs.root(0, '.git') --[[@as string]]
      local full_path = vim.fn.expand '%:p' --[[@as string]]
      local path = full_path:gsub(root .. '/', '')
      if vim.api.nvim_win_get_width(0) / 2 < #path then
        -- navic won't fit well in lualine
        return
      end

      table.insert(opts.sections.lualine_c, {
        'navic',
        -- nil or 'static' seem to work here
        color_correction = nil,
        color = 'BufferLineTruncMarker',
      })
    end,
  },
}
