-- NOTE: 2025-07-02
-- today I have green as the main accent color
-- someday I may change it to purple

-- ---
--
-- Helper function to convert hex to RGB
local function hex_to_rgb(hex_color)
  hex_color = hex_color:gsub('#', '') -- Remove '#' if present
  local r = tonumber(hex_color:sub(1, 2), 16)
  local g = tonumber(hex_color:sub(3, 4), 16)
  local b = tonumber(hex_color:sub(5, 6), 16)
  return r, g, b
end

-- Helper function to convert RGB to hex
local function rgb_to_hex(r, g, b)
  return string.format('#%02X%02X%02X', r, g, b)
end

-- lighten a hex color by a given amount
local function lighten(hex_color, amount)
  -- Convert hex color to RGB
  local r, g, b = hex_to_rgb(hex_color)

  -- Lighten each color channel
  r = math.min(255, r + amount)
  g = math.min(255, g + amount)
  b = math.min(255, b + amount)

  -- Convert back to hex
  return rgb_to_hex(r, g, b)
end

local function darken(hex_color, amount)
  -- Convert hex color to RGB
  local r, g, b = hex_to_rgb(hex_color)

  -- 256 is 100%
  -- amount is the percentage of 256 to decrease by, so if 10% decrease, amount = 0.1
  amount = math.floor(amount * 256)

  -- Darken each color channel
  r = math.max(0, r - amount)
  g = math.max(0, g - amount)
  b = math.max(0, b - amount)

  -- Convert back to hex
  return rgb_to_hex(r, g, b)
end

local config = {
  -- TODO: use vim.extend_table to extend these configs

  highlights = {
    keyword = { fg = C.ui.colors.red, style = { 'nocombine' } },
    type = { C.ui.colors.yellow, style = { 'nocombine' } },
  },
}

return {
  theme = {
    variant = 'winter', -- 'winter'|'fall'|'spring'|'summer'
    accent = 'green',
  },

  --  example for API: vim.api.nvim_set_hl(0, '@org.keyword.todo', { fg = '#f7a49c' })
  overrides = {
    Folded = {
      fg = C.ui.colors.lightgray,
      bg = C.ui.colors.winter.mantle,
      -- style = { 'italic' },
    },

    Keyword = config.highlights.keyword,
    ['@keyword'] = config.highlights.keyword,
    ['@keyword.coroutine'] = config.highlights.keyword,
    ['@keyword.operator'] = config.highlights.keyword,
    ['@annotation'] = config.highlights.keyword,

    -- highlight on yank
    IncSearch = { bg = C.ui.colors.orange, fg = C.ui.colors.black },

    ['@comment'] = { fg = C.ui.colors.gray, style = { 'italic' } },
    ['@operator'] = { fg = C.ui.colors.lightgray, style = { 'bold' } },

    ['@function'] = { C.ui.colors.green, style = { 'bold' } },
    ['@lsp.typemod.function.declaration.javascript'] = { C.ui.colors.lime, style = { 'bold' } },
    ['@constant'] = { C.ui.colors.white, style = { 'italic' } },
    ['@lsp.mod.readonly.javascript'] = { C.ui.colors.white, style = { 'nocombine' } },

    ['@module'] = { C.ui.colors.blue, style = { 'nocombine' } },
    -- ['@variable.member'] = { C.ui.colors.snow, style = { 'nocombine' } },

    ['@function.builtin.go'] = { C.ui.colors.white, style = { 'nocombine' } },
    ['@type.definition.go'] = { fg = C.ui.colors.yellow, style = { 'nocombine' } },
    ['@variable.builtin.typescript'] = { C.ui.colors.white, style = { 'nocombine' } },
    -- ['@keyword.import.typescript'] = { C.ui.colors.blue, style = { 'nocombine' } },

    ['@lsp.mod.readonly.typescript'] = { C.ui.colors.white, style = { 'nocombine' } },
    ['@attribute.typescript'] = { C.ui.colors.white, style = { 'nocombine' } },
    -- ['@variable.parameter.typescript'] = { C.ui.colors.white, style = { 'bold' } },

    Type = config.highlights.type,
    ['@type'] = config.highlights.type,

    ['@markup.raw'] = { fg = '#AFDFE6' }, -- inline `code` in markdown

    ['@markup.link.label.markdown_inline'] = { fg = C.ui.colors.blue }, -- inline `code` in markdown
    MarkviewPalette7Fg = { fg = C.ui.colors.blue, style = { 'underline' } }, -- markview inline hint
    SpellBad = { style = { 'italic', 'underdotted' } }, -- spelling mistakes
    SpellCap = { style = {} }, -- style when a word should start with a capital letter
    TabLineSel = { fg = C.ui.colors.green, bg = C.ui.colors.inactivegray, style = { 'bold' } },

    LineNrAbove = { fg = C.ui.colors.gray },
    LineNrBelow = { fg = C.ui.colors.gray },
    AvanteInlineHint = { fg = C.ui.colors.lightgray },
    MarkviewHeading1 = { fg = C.ui.colors.white, bg = darken(C.ui.colors.gray, 0.3), style = { 'bold' } },
    ['@markup.heading.1.markdown'] = { fg = C.ui.colors.white, bg = darken(C.ui.colors.gray, 0.3), style = { 'bold' } },
    -- MarkviewHeading2 = { fg = lighten(C.ui.colors.subtext, 0.1), bg = darken(C.ui.colors.gray, 0.3), style = { 'bold' } },
    ['@markup.heading.2.markdown'] = { fg = lighten(C.ui.colors.blue, 0.1), bg = darken(C.ui.colors.gray, 0.3), style = { 'bold' } },
    -- MarkviewHeading3 = { fg = C.ui.colors.lightgray, bg = darken(C.ui.colors.gray, 0.4), style = { 'bold' } },
    -- ['@markup.heading.3.markdown'] = { fg = C.ui.colors.lightgray, bg = darken(C.ui.colors.gray, 0.4), style = { 'bold' } },
    DiffAdd = { fg = C.ui.colors.green, bg = C.ui.colors.comment }, -- markview heading 1
    DiffChange = { fg = C.ui.colors.green, bg = C.ui.colors.gray }, -- markview heading 1
    Underlined = { style = { 'underline', 'italic' } },
    LspReferenceRead = { bg = C.ui.colors.gray },

    -- orgmode
    ['@org.plan.org'] = { fg = C.ui.colors.gray },
    ['@org.headline.level1.org'] = { fg = C.ui.colors.white, style = { 'bold' } },
    ['@org.headline.level2.org'] = { fg = C.ui.colors.subtext, style = { 'bold' } },
    ['@org.headline.level3.org'] = { fg = C.ui.colors.white, style = { 'nocombine' } },
    ['@org.headline.level4.org'] = { fg = C.ui.colors.white, style = { 'nocombine' } },
    ['@org.timestamp.active.org'] = { fg = C.ui.colors.light_red },
    ['@org.agenda.day'] = { fg = C.ui.colors.light_red },
    -- ['@org.agenda.scheduled'] = { fg = C.ui.colors.lime },
    ['@org.keyword.active.org'] = { fg = C.ui.colors.light_red },
    ['@org.keyword.todo'] = { fg = C.ui.colors.red, style = { 'bold' } },
    ['@org.keyword.done'] = { fg = C.ui.colors.green, style = { 'bold' } },
    ['@org.tag.org'] = { fg = C.ui.colors.purple },
    ['@org.hyperlink.org'] = { fg = C.ui.colors.blue, style = { 'underline' } },
    ['@org.hyperlink.url.org'] = { style = { 'italic' } },
    ['@org.hyperlink.desc.org'] = { fg = C.ui.colors.blue, style = { 'italic' } },
    ['@org.priority.highest.org'] = { fg = C.ui.colors.orange, style = { 'italic' } },

    FlashLabel = { bg = C.ui.colors.lightgray, fg = C.ui.colors.black },
    -- lua
    -- ['@lsp.typemod.variable.defaultLibrary.lua'] = { fg = C.ui.colors.blue, style = { 'nocombine' } },
    -- ['@lsp.typemod.function.defaultLibrary.lua'] = { fg = C.ui.colors.blue, style = { 'nocombine' } },
    -- ['@function.builtin.lua'] = { fg = C.ui.colors.blue, style = { 'nocombine' } },

    DiagnosticUnderlineError = { fg = C.ui.colors.lightgray, style = { 'nocombine' } },
  },
  integrations = {
    cmp = true,
    gitsigns = true,
    lualine = true,
    mini = {
      enable = true,
      animate = true,
      clue = true,
      completion = true,
      cursorword = true,
      deps = true,
      diff = true,
      files = true,
      hipatterns = true,
      icons = true,
      indentscope = true,
      jump = true,
      jump2d = true,
      map = true,
      notify = true,
      operators = true,
      pick = true,
      starters = true,
      statusline = true,
      surround = true,
      tabline = true,
      test = true,
      trailspace = true,
    },
    telescope = true,
    which_key = true,
  },
}
