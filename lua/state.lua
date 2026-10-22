--- Global source of truth for internal app state.
---
---@class State
---@field colors OmarchyColors
---@field agents AgentsState
---@field toggle_term_bufs table<number,number> tabpage id -> its toggle terminal buffer
---@field recording_macro boolean
---@field overseer_task_count number?
---@field time string?
---@field branch_commits_ahead_of_origin number?
---@field branch_commits_behind_origin number?
---@field NamedTabs string?
---@field git_diff_revision string?
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
  overseer_task_count = nil,
  git_diff_revision = nil,
  autoinsert_on_term = true,
  -- every tab page owns its own toggle terminal: tabpage id -> buffer
  toggle_term_bufs = {},
}

return M
