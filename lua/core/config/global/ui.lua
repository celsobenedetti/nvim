-- TODO: extract "colors.lua" to separate config file
local colors = {
  default_nvim = {
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

  evergarden = {
    black = '#171C1F',
    white = '#F8F9E8',
    red = '#F57F82',
    green = '#CAE0A7',
    blue = '#B2CFED',
    yellow = '#F5D098',
    gray = '#58686D',
    darkgray = '#1C2225',
    lightgray = '#4A585C',
    inactivegray = '#313B40',
    comment = '#232A2E',
  },
}

local M = {
  colorscheme = 'evergarden',
  colors = colors.evergarden,

  background = 'dark',

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

return M
