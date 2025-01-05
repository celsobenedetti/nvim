C = {
  Globals = {
    copilot = true,
    autoformat = true,
    completion = true, -- cmp
    diagnostics = true,
    performance = false, -- disable heavy plugins
    hardtime = false,

    --- Path to the directory where md files for GPT chats are stored.
    gpt_chats_path = os.getenv 'NOTES' .. '/.local/chats',
  },

  UI = require 'c.core.config.ui',
}

C.CWD = require 'c.lib.utils.cwd'

-- iterate over all global variables
for key, value in pairs(C.Globals) do
  if value == nil or value == '' then
    C.Globals.key = ''
    print('WARN: global variable not set:', key)
  end
end
