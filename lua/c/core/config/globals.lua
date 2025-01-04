Globals = {
  copilot = true,
  autoformat = true,
  completion = true, -- cmp
  diagnostics = true,

  --- Path to the directory where md files for GPT chats are stored.
  gpt_chats_path = os.getenv 'NOTES' .. '/.local/chats',
}

UI = {
  colorscheme_1 = 'default',
  colorscheme_2 = 'rose-pine',
  colorscheme_3 = 'gruvbox',
  colorscheme_4 = 'github_dark_high_contrast',
}

-- iterate over all global variables
for key, value in pairs(Globals) do
  if value == nil or value == '' then
    Globals.key = ''
    print('WARN: global variable not set:', key)
  end
end
