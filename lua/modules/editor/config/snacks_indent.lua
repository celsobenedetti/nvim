---@class snacks.indent.Config
local M = {
  indent = {
    priority = 1,
    enabled = true, -- enable indent guides
    char = '│',
    only_scope = false, -- only show indent guides of the scope
    only_current = false, -- only show indent guides in the current window
    hl = 'SnacksIndentScope', ---@type string|string[] hl groups for indent guides
  },
  animate = {
    enabled = true,
    style = 'out',
    easing = 'linear',
    duration = {
      step = 20, -- ms per step
      total = 500, -- maximum duration
    },
  },
  scope = {
    enabled = true, -- enable highlighting the current scope
    priority = 200,
    char = '│',
    underline = false, -- underline the start of the scope
    only_current = true, -- only show scope in the current window
    hl = 'SnacksIndent', ---@type string|string[] hl group for scopes
  },
  chunk = {
    enabled = false,
    only_current = false,
    priority = 200,
    hl = 'SnacksIndentChunk', ---@type string|string[] hl group for chunk scopes
    char = {
      corner_top = '┌',
      corner_bottom = '└',
      -- corner_top = "╭",
      -- corner_bottom = "╰",
      horizontal = '─',
      vertical = '│',
      arrow = '>',
    },
  },
  blank = {
    char = ' ',
    hl = 'SnacksIndentBlank', ---@type string|string[] hl group for blank spaces
  },
  filter = function(buf)
    return vim.g.snacks_indent ~= false and vim.b[buf].snacks_indent ~= false and vim.bo[buf].buftype == ''
  end,
}

return M
