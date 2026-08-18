--- Global source of truth for internal app state.
---
---@class State
---@field colors table
---@field claude_bufnr number
---@field opencode_bufnr number
---@field toggle_term_bufnr number
---@field recording_macro boolean
---@field time string?
---@field branch_commits_ahead_of_origin number?
---@field branch_commits_behind_origin number?
---@field NamedTabs string?
---@field zen_mode boolean
---@field capture boolean
---@field org_current_task string?
---@field insert_when_entering_terminal boolean
---@field omarchy_colorscheme table
local M = {
  lsp = true,
  autoformat = true,
  completion = true,
  statusline_show_filepath = true,
  statusline_show_position = false,
  statusline_show_time = false,
}

return M
