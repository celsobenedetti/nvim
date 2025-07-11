--- Global options
local M = {
  copilot = false,
  supermaven = true,

  autoformat = true, -- fmt
  completion = true, -- cmp
  diagnostics = true,
  performance = false, -- disable optional/heavy plugins
  hardtime = true,
  winbar = true,

  notes_path = os.getenv 'NOTES',
  gpt_chats_path = os.getenv 'GPT_CHATS',

  fold = true,
}

-- iterate and validate all global variables
for key, value in pairs(M) do
  if value == nil or value == '' then
    C.opt.key = ''
    print('WARN global variable not set:', key)
  end
end

M.notes_path = M.notes_path or ''
M.gpt_chats_path = M.gpt_chats_path or M.notes_path .. '/.local/chats'

return M
