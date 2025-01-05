C = {
  global = {
    copilot = true,
    autoformat = true, -- fmt
    completion = true, -- cmp
    diagnostics = true,
    performance = false, -- disable heavy plugins
    hardtime = false,

    notes_path = os.getenv 'NOTES',
  },

  UI = require 'c.core.config.ui',
}

C.CWD = require 'c.lib.utils.cwd'

-- iterate and validate all global variables
for key, value in pairs(C.global) do
  if value == nil or value == '' then
    C.global.key = ''
    print('WARNING: global variable not set:', key)
  end
end

C.global.notes_path = C.global.notes_path or ''
C.global.gpt_chats_path = C.global.notes_path .. './local/chats' -- target directory for GPT chats.md files
