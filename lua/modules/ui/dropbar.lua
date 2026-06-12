return {
  {
    'Bekaboo/dropbar.nvim',
    enabled = vim.g.dropbar,
    opts = function(_, opts)
      opts.bar = {
        enable = function(buf, win, _)
          if not vim.api.nvim_buf_is_valid(buf) or not vim.api.nvim_win_is_valid(win) then
            return false
          end
          if vim.fn.win_gettype(win) ~= '' or vim.bo[buf].ft == 'help' then
            return false
          end
          local stat = vim.uv.fs_stat(vim.api.nvim_buf_get_name(buf))
          if stat and stat.size > 1024 * 1024 then
            return false
          end
          return vim.bo[buf].bt == 'terminal' or true
        end,
        sources = function(buf, _)
          local sources = require('dropbar.sources')
          local utils = require('dropbar.utils')
          if vim.bo[buf].ft == 'markdown' or vim.bo[buf].buftype == 'nofile' then
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
