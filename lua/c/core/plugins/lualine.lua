local theme = {
  normal = {
    a = { bg = C.UI.colors.gray, fg = C.UI.colors.black, gui = 'bold' },
    b = { bg = C.UI.colors.lightgray, fg = C.UI.colors.white },
    c = { bg = C.UI.colors.darkgray, fg = C.UI.colors.gray },
  },
  insert = {
    a = { bg = C.UI.colors.blue, fg = C.UI.colors.black, gui = 'bold' },
    b = { bg = C.UI.colors.lightgray, fg = C.UI.colors.white },
    c = { bg = C.UI.colors.lightgray, fg = C.UI.colors.white },
  },
  visual = {
    a = { bg = C.UI.colors.yellow, fg = C.UI.colors.black, gui = 'bold' },
    b = { bg = C.UI.colors.lightgray, fg = C.UI.colors.white },
    c = { bg = C.UI.colors.inactivegray, fg = C.UI.colors.black },
  },
  replace = {
    a = { bg = C.UI.colors.red, fg = C.UI.colors.black, gui = 'bold' },
    b = { bg = C.UI.colors.lightgray, fg = C.UI.colors.white },
    c = { bg = C.UI.colors.black, fg = C.UI.colors.white },
  },
  command = {
    a = { bg = C.UI.colors.green, fg = C.UI.colors.black, gui = 'bold' },
    b = { bg = C.UI.colors.lightgray, fg = C.UI.colors.white },
    c = { bg = C.UI.colors.inactivegray, fg = C.UI.colors.black },
  },
  inactive = {
    a = { bg = C.UI.colors.darkgray, fg = C.UI.colors.gray, gui = 'bold' },
    b = { bg = C.UI.colors.darkgray, fg = C.UI.colors.gray },
    c = { bg = C.UI.colors.darkgray, fg = C.UI.colors.gray },
  },
}

local function getFg(name)
  local hl = vim.api.nvim_get_hl(0, { name = name, link = false })
  local fg = hl and hl.fg or hl.foreground
  return { fg = string.format('#%06x', fg), bg = 'none' } or nil
end

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
      -- PERF: we don't need this lualine require madness 🤷
      local lualine_require = require 'lualine_require'
      lualine_require.require = require
      local root = vim.fs.root(0, '.git') --[[@as string]]

      vim.o.laststatus = vim.g.lualine_laststatus

      local opts = {
        options = {
          theme = theme,
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
                return C.UI.icons.kinds.Folder .. root:match '([^/]+)$'
              end,
            },
            {
              'diagnostics',
              symbols = {
                error = C.UI.icons.diagnostics.Error,

                hint = C.UI.icons.diagnostics.Hint,
              },
            },

            {
              'filetype',
              icon_only = true,
              separator = '',
              padding = { left = 1, right = 0 },
            },
            {
              function()
                local path = vim.fn.expand '%:p' --[[@as string]]
                -- remove the root from the path
                return path:gsub(root .. '/', '')
              end,
            },
          },
          lualine_x = {
            -- stylua: ignore
            {
              function() return require("noice").api.status.command.get() end,
              cond = function() return package.loaded["noice"] and require("noice").api.status.command.has() end,
              color = function() return getFg("Statement") end,
            },
            -- stylua: ignore
            {
              function() return require("noice").api.status.mode.get() end,
              cond = function() return package.loaded["noice"] and require("noice").api.status.mode.has() end,
              color = function() return getFg("Constant") end,
            },
            -- stylua: ignore
            {
              function() return "  " .. require("dap").status() end,
              cond = function() return package.loaded["dap"] and require("dap").status() ~= "" end,
              color = function() return getFg("Debug") end,
            },
            -- stylua: ignore
            {
              require("lazy.status").updates,
              cond = require("lazy.status").has_updates,
              color = function() return getFg("Special") end,
            },
            {
              'diff',
              symbols = {
                added = C.UI.icons.git.added,
                modified = C.UI.icons.git.modified,
                removed = C.UI.icons.git.removed,
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
