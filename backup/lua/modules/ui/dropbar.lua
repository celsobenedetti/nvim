return {
  {
    'Bekaboo/dropbar.nvim',
    event = 'VeryLazy',
    enabled = vim.g.dropbar,
    opts = function(_, opts)
      opts.bar = {
        sources = function(buf, _)
          local sources = require 'dropbar.sources'
          local utils = require 'dropbar.utils'
          if vim.bo[buf].ft == 'markdown' then
            return {}
          end
          if vim.bo[buf].buftype == 'terminal' then
            return { sources.terminal }
          end
          return {
            sources.path,
            -- utils.source.fallback {
            --   sources.lsp,
            --   -- sources.treesitter,
            -- },
          }
        end,
      }

      opts.icons = {
        kinds = {
          symbols = {
            Folder = '',
          },
        },
        ui = {
          bar = {
            separator = '  ',
          },
        },
      }
    end,
  },
}
