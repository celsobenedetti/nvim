vim.g.colorscheme = 'evergarden'
local background = 'dark'

local M = {}

M.default = {
  black = '#0B0C11',
  white = '#d7dae1',
  red = '#ffbcb5',
  light_red = '#ffbcb5',
  green = '#7FAD8A',
  blue = '#7FAAC9',
  yellow = '#f4d88c',
  gray = '#d7dae1',
  darkgray = '#0B0C11',
  lightgray = '#d7dae1',
  inactivegray = '#303340',
  comment = '#2c2e33',

  subtext = '#ADC9BC',

  bg = '#24283b',
}

M.tokyonight = {
  bg = '#24283b',
  bg_dark = '#1f2335',
  bg_dark1 = '#1b1e2d',
  bg_highlight = '#292e42',
  blue = '#7aa2f7',
  blue0 = '#3d59a1',
  blue1 = '#2ac3de',
  blue2 = '#0db9d7',
  blue5 = '#89ddff',
  blue6 = '#b4f9f8',
  blue7 = '#394b70',
  comment = '#565f89',
  cyan = '#7dcfff',
  dark3 = '#545c7e',
  dark5 = '#737aa2',
  fg = '#c0caf5',
  fg_dark = '#a9b1d6',
  fg_gutter = '#3b4261',
  green = '#9ece6a',
  green1 = '#73daca',
  green2 = '#41a6b5',
  magenta = '#bb9af7',
  magenta2 = '#ff007c',
  orange = '#ff9e64',
  purple = '#9d7cd8',
  red = '#f7768e',
  red1 = '#db4b4b',
  teal = '#1abc9c',
  terminal_black = '#414868',
  yellow = '#e0af68',
  git = {
    add = '#449dab',
    change = '#6183bb',
    delete = '#914c54',
  },
}

M.evergarden = {
  bg = '#232A2E',

  black = '#171C1F',
  white = '#F8F9E8',
  -- red = '#F57F82',
  red = '#E67E81',
  light_green = '#CAE0A7',
  green = '#AFC991',
  light_red = '#ffbcb5',
  blue = '#B2CFED',

  sand = '#c4a16c',
  yellow = '#F5D098',
  gray = '#58686D',
  darkgray = '#1C2225',
  lightgray = '#839E9A',
  inactivegray = '#313B40',
  comment = '#232A2E',
  subtext = '#ADC9BC',

  lime = '#DBE6AF',
  aqua = '#ADDEB9',
  skye = '#ACE0D4',
  snow = '#AFDFE6',
  purple = '#D0BBF0',
  pink = '#F3C0E5',
  cherry = '#F6CEE5',
  orange = '#F7A182',

  winter = {
    surface0 = '#2D393D',
    base = '#1D2428',
    mantle = '#191E21',
  },

  fall = {
    text = '#F8F9E8',
    subtext1 = '#ADC9BC',
    subtext0 = '#96B4AA',
    overlay2 = '#839E9A',
    overlay1 = '#6F8788',
    overlay0 = '#58686D',
    surface2 = '#4A585C',
    surface1 = '#3D494D',
    surface0 = '#313B40',
    base = '#232A2E',
    mantle = '#1C2225',
    crust = '#171C1F',
  },

  summer = {
    orange = '#C1866B',
    red = '#C0696B',
    yellow = '#BC9C6B',
    lime = '#A7AF70',
    green = '#91AC75',
    aqua = '#7BAA92',
    skye = '#79A39B',
    snow = '#7FA0AA',
    blue = '#8CA0BB',
    purple = '#AB9AC6',
    pink = '#CA9EBD',
    cherry = '#CEABBF',
    text = '#171C1F',
    subtext1 = '#415055',
    subtext0 = '#526469',
    overlay2 = '#63787D',
    overlay1 = '#758A90',
    overlay0 = '#879DA4',
    surface2 = '#9CB2B8',
    surface1 = '#B4C6CC',
    surface0 = '#CED9E0',
    base = '#D7E1EB',
    mantle = '#C8D5E1',
    crust = '#BDCBDB',
  },
}

local gtk_theme = vim.fn.system 'gsettings get org.gnome.desktop.interface color-scheme'
vim.g.background = gtk_theme:find 'dark' and 'dark' or 'light'
vim.g.background = background
vim.cmd('set background=' .. vim.g.background)
if vim.g.background == 'light' then
  vim.g.colorscheme = 'default'
end

local colors = M[vim.g.colorscheme] or M.evergarden

colors.bg2 = vim.g.background == 'dark' and colors.darkgray or colors.lightgray
colors.subtext = vim.g.background == 'dark' and colors.subtext or colors.black

return colors
