local Lualine = require 'modules.ui.config.lualine'

return {
  {
    'nvim-lualine/lualine.nvim',
    event = 'VeryLazy',
    init = function()
      vim.g.lualine_laststatus = vim.o.laststatus
      if vim.fn.argc(-1) > 0 then
        -- set an empty statusline till lualine loads
        vim.o.statusline = ' '
      else
        -- hide the statusline on the starter page
        vim.o.laststatus = 0
      end
    end,
    opts = function()
      -- LazyVim: we don't need this lualine require madness 🤷
      -- local lualine_require = require 'lualine_require'
      -- lualine_require.require = require
      local root = vim.fs.root(0, '.git') --[[@as string]]

      vim.o.laststatus = vim.g.lualine_laststatus

      local opts = {
        options = {
          -- theme = Lualine.theme,
          globalstatus = vim.o.laststatus == 3,
          disabled_filetypes = { statusline = { 'dashboard', 'alpha', 'ministarter', 'snacks_dashboard' } },
        },
        sections = {
          lualine_a = { 'mode' },
          lualine_b = { 'branch' },
          lualine_c = {
            {
              function()
                -- split 'root' strin by '/' and get the last element
                return C.ui.icons.kinds.Folder .. root:match '([^/]+)$'
              end,
            },
            {
              'diagnostics',
              symbols = {
                error = C.ui.icons.diagnostics.Error,

                hint = C.ui.icons.diagnostics.Hint,
              },
            },

            {
              'filetype',
              icon_only = true,
              separator = '',
              padding = { left = 1, right = 0 },
            },
            {
              -- TODO: fix hg config
              color = { bg = C.ui.colors.darkgray, fg = C.ui.colors.gray },
              Lualine.pretty_path,
            },
          },
          lualine_x = {
            -- stylua: ignore
            {
              function() return require("noice").api.status.command.get() end,
              cond = function() return package.loaded["noice"] and require("noice").api.status.command.has() end,
              color = function() return Lualine.fg("Statement") end,
            },
            -- stylua: ignore
            {
              function() return require("noice").api.status.mode.get() end,
              cond = function() return package.loaded["noice"] and require("noice").api.status.mode.has() end,
              color = function() return Lualine.fg("Constant") end,
            },
            -- stylua: ignore
            {
              function() return "  " .. require("dap").status() end,
              cond = function() return package.loaded["dap"] and require("dap").status() ~= "" end,
              color = function() return Lualine.fg("Debug") end,
            },

            {
              function()
                return ' ' .. _G.orgmode.statusline()
              end,
              cond = function()
                return true
              end,
              color = function()
                return Lualine.fg 'Debug'
              end,
            },


            -- stylua: ignore
            {
              require("lazy.status").updates,
              cond = require("lazy.status").has_updates,
              color = function() return Lualine.fg("Special") end,
            },
            {
              'diff',
              symbols = {
                added = C.ui.icons.git.added,
                modified = C.ui.icons.git.modified,
                removed = C.ui.icons.git.removed,
              },
              source = function()
                local gitsigns = vim.b.gitsigns_status_dict
                if gitsigns then
                  return {
                    added = gitsigns.added,
                    modified = gitsigns.changed,
                    removed = gitsigns.removed,
                  }
                end
              end,
            },
          },
          lualine_y = {
            { 'progress', separator = ' ', padding = { left = 1, right = 0 } },
            { 'location', padding = { left = 0, right = 1 } },
          },
          lualine_z = {
            function()
              return ' ' .. os.date '%R'
            end,
          },
        },
        extensions = { 'neo-tree', 'lazy' },
      }

      return opts
    end,
  },
}
