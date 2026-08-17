--- Single source of truth for `lib.*` submodules: `local lib = require('lib')`
--- instead of a per-file `local lib = { x = require('lib.x') }` table.
---
--- Only put functions here that are actually shared across files. Data/state
--- (colors, dirs, env, ...) belongs in the state module, not here. A helper
--- used by exactly one file should just stay local to that file.
---@class Lib
---@field buffers LibBuffers
---@field cmd LibCmd
---@field cmdline LibCmdline
---@field colors LibColors
---@field cwd LibCwd
---@field fold LibFold
---@field fs LibFs
---@field fzf LibFzf
---@field gx LibGx
---@field jump LibJump
---@field keys LibKeys
---@field notes LibNotes
---@field org_fzf LibOrgFzf
---@field orgmode LibOrgmode
---@field strings LibStrings
---@field tab LibTab
---@field term LibTerm
---@field tmux LibTmux
---@field utils LibUtils
---@field visual LibVisual
local M = {}

setmetatable(M, {
  __index = function(t, key)
    local mod = require('lib.' .. key)
    rawset(t, key, mod)
    return mod
  end,
})

return M
