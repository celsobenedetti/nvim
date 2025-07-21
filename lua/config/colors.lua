local M = {}

M.colorscheme = "evergarden"
M.background = "dark"

local default_nvim = {
  black = "#0B0C11",
  white = "#d7dae1",
  red = "#ffbcb5",
  light_red = "#ffbcb5",
  green = "#7FAD8A",
  blue = "#7FAAC9",
  yellow = "#f4d88c",
  gray = "#d7dae1",
  darkgray = "#0B0C11",
  lightgray = "#303340",
  inactivegray = "#303340",
  comment = "#2c2e33",

  subtext = "#ADC9BC",
}

local evergarden = {
  black = "#171C1F",
  white = "#F8F9E8",
  -- red = '#F57F82',
  red = "#E67E81",
  -- green = '#CAE0A7',
  green = "#AFC991",
  light_red = "#ffbcb5",
  blue = "#B2CFED",
  yellow = "#F5D098",
  gray = "#58686D",
  darkgray = "#1C2225",
  lightgray = "#839E9A",
  inactivegray = "#313B40",
  comment = "#232A2E",
  subtext = "#ADC9BC",

  lime = "#DBE6AF",
  aqua = "#ADDEB9",
  skye = "#ACE0D4",
  snow = "#AFDFE6",
  purple = "#D0BBF0",
  pink = "#F3C0E5",
  cherry = "#F6CEE5",
  orange = "#F7A182",

  winter = {
    surface0 = "#2D393D",
    base = "#1D2428",
    mantle = "#191E21",
  },

  fall = {
    text = "#F8F9E8",
    subtext1 = "#ADC9BC",
    subtext0 = "#96B4AA",
    overlay2 = "#839E9A",
    overlay1 = "#6F8788",
    overlay0 = "#58686D",
    surface2 = "#4A585C",
    surface1 = "#3D494D",
    surface0 = "#313B40",
    base = "#232A2E",
    mantle = "#1C2225",
    crust = "#171C1F",
  },
}

local colorscheme = evergarden
return vim.tbl_deep_extend("keep", M, colorscheme)
