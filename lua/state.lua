--- Single source of truth for internal app state/config: `local state = require('state')`.
---
--- vim.g is reserved strictly for values a plugin or Vimscript actually reads
--- directly from that namespace (an external contract) — e.g. mapleader,
--- clipboard, db_ui_use_nerd_fonts. Everything else that used to live in
--- vim.g out of habit belongs here instead.
---
--- Only put read-at-or-near-startup config/data here. A value used by
--- exactly one file should just stay local to that file.
---@class State
---@field colors table
---@field icons table
---@field hl table
local M = {}

return M
