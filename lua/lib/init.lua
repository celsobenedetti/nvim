--- Single source of truth for `lib.*` submodules, exposed globally as `lib`
---
--- These are functions shared across files.
--- Data/state belongs in the state module, not here.
---
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

-- Individual modules are loaded JIT when first accessed. `__index`
-- fires on a miss, so each submodule is `require`d at most once.
setmetatable(M, {
  __index = function(t, key)
    local mod = require('lib.' .. key)
    rawset(t, key, mod)
    return mod
  end,
})

return M
