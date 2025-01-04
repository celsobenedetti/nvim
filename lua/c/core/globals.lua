-- ---
--
-- Global variables
--
-- ---

vim.g.autoformat = true
vim.g.copilot = true
vim.g.completion = true -- cmp
vim.g.diagnostics = true

vim.g.colorscheme_1 = 'default'
vim.g.colorscheme_2 = 'rose-pine'
vim.g.colorscheme_3 = 'gruvbox'
vim.g.colorscheme_4 = 'github_dark_high_contrast'

Globals = {
  --- Path to the directory where md files for GPT chats are stored.
  gpt_chats_path = os.getenv 'NOTES' .. '/.local/chats',
}

-- iterate over all global variables
for key, value in pairs(Globals) do
  if value == nil or value == '' then
    Globals.key = ''
    print('WARN: global variable not set:', key)
  end
end
