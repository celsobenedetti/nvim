--- Libs are individual modules holding util functions that
--- are shared across files.
--- Individual modules are loaded JIT when first accessed.
---
---@class Lib
---@field Diff LibDiff
---@field buffers LibBuffers
---@field cmd LibCmd
---@field cmd_output LibCmdOutput
---@field cmdline LibCmdline
---@field colors LibColors
---@field cwd LibCwd
---@field fold LibFold
---@field fold_hl LibFoldHl
---@field fs LibFs
---@field fzf LibFzf
---@field git LibGit
---@field gx LibGx
---@field hunk LibHunk
---@field jump LibJump
---@field keys LibKeys
---@field notes LibNotes
---@field obsidian LibObsidian
---@field org LibOrg
---@field org_do LibOrgDo
---@field org_focus LibOrgFocus
---@field org_fzf LibOrgFzf
---@field strings LibStrings
---@field tab LibTab
---@field term LibTerm
---@field tmux LibTmux
---@field visual LibVisual
---@field overseer LibOverseer
---@field diff_filepath LibDiffFilepath
---@field zen LibZen
local M = {}

setmetatable(M, {
  -- `__index` fires on a miss, so each submodule is lazyly `require`d
  -- at most once, when first invoked
  __index = function(t, key)
    local mod = require('lib.' .. key)
    rawset(t, key, mod)
    return mod
  end,
})

return M
