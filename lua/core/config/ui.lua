local M = {
  colorscheme_1 = 'default',
  colorscheme_2 = 'rose-pine',
  colorscheme_3 = 'gruvbox',
  colorscheme_4 = 'github_dark_high_contrast',

  colors = {
    black = '#0B0C11',
    white = '#d7dae1',
    red = '#ffbcb5',
    green = '#7FAD8A',
    blue = '#7FAAC9',
    yellow = '#f4d88c',
    gray = '#d7dae1',
    darkgray = '#0B0C11',
    lightgray = '#303340',
    inactivegray = '#303340',
    comment = '#2c2e33',
  },

  icons = {
    diagnostics = {
      Error = ' ',
      Warn = ' ',
      Hint = ' ',
      Info = ' ',
    },
    git = {
      added = ' ',
      modified = ' ',
      removed = ' ',
    },
    kinds = {
      Array = ' ',
      Boolean = '󰨙 ',
      Class = ' ',
      Codeium = '󰘦 ',
      Color = ' ',
      Control = ' ',
      Collapsed = ' ',
      Constant = '󰏿 ',
      Constructor = ' ',
      Copilot = ' ',
      Enum = ' ',
      EnumMember = ' ',
      Event = ' ',
      Field = ' ',
      File = ' ',
      Folder = ' ',
      Function = '󰊕 ',
      Interface = ' ',
      Key = ' ',
      Keyword = ' ',
      Method = '󰊕 ',
      Module = ' ',
      Namespace = '󰦮 ',
      Null = ' ',
      Number = '󰎠 ',
      Object = ' ',
      Operator = ' ',
      Package = ' ',
      Property = ' ',
      Reference = ' ',
      Snippet = '  ',
      String = ' ',
      Struct = '󰆼 ',
      Supermaven = ' ',
      TabNine = '󰏚 ',
      Text = ' ',
      TypeParameter = ' ',
      Unit = ' ',
      Value = ' ',
      Variable = '󰀫 ',
    },
    chars = {
      ellipsis = '…',
    },
  },

  lazy = {
    icons = {
      cmd = '⌘',
      config = '🛠',
      event = '📅',
      ft = '📂',
      init = '⚙',
      keys = '🗝',
      plugin = '🔌',
      runtime = '💻',
      require = '🌙',
      source = '📄',
      start = '🚀',
      task = '📌',
      lazy = '💤 ',
    },
  },

  position = {
    center = {
      row = '50%',
      col = '50%',
    },
  },

  set_colorscheme = require('lib.utils.set_colorscheme').run,
}

---@type table<string, vim.api.keyset.highlight>
local groups = {
  -- Winbar styling.
  WinBar = { fg = M.colors.fg, bg = M.colors.transparent_black },
  WinBarNC = { bg = M.colors.transparent_black },
  WinBarDir = { fg = M.colors.bright_magenta, bg = M.colors.transparent_black, italic = true },
  WinBarSeparator = { fg = M.colors.green, bg = M.colors.transparent_black },
}

for group, opts in pairs(groups) do
  vim.api.nvim_set_hl(0, group, opts)
end

return M
