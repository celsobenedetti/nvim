C = {
  Globals = {
    copilot = true,
    autoformat = true,
    completion = true, -- cmp
    diagnostics = true,

    --- Path to the directory where md files for GPT chats are stored.
    gpt_chats_path = os.getenv 'NOTES' .. '/.local/chats',
  },

  UI = {
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
    },
  },
}

C.UI.set_colorscheme = require('c.lib.util.set_colorscheme').run

-- iterate over all global variables
for key, value in pairs(C.Globals) do
  if value == nil or value == '' then
    C.Globals.key = ''
    print('WARN: global variable not set:', key)
  end
end
