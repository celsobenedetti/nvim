-- Graceful :wqa that writes all valid buffers and quits, ignoring
-- inconsequential ones (unnamed buffers, etc)
vim.api.nvim_create_user_command('Wqa', function()
  lib.buffers.wqa()
end, { desc = 'write all valid buffers and quit' })

local abbreviations = {
  W = 'w',
  Wa = 'wa',
  WA = 'wa',
  Wq = 'wq',
  WQ = 'wq',
  Wqa = 'Wqa',
  wqa = 'Wqa',
  Q = 'q',
  Qa = 'qa',
  Bd = 'bd',
  E = 'e',
  Tabclose = 'tabclose',
  Tabnew = 'tabnew',
  Set = 'set',
  git = 'Git',
  commit = 'tab Git commit',
  Tab = 'tab',
  cfilter = 'Cfilter',
  grep = 'Grep',
  fd = 'Fd',
}

if vim.env.ORG_INBOX then
  abbreviations['in'] = string.format(':e %s', vim.env.ORG_INBOX)
  abbreviations['inbox'] = string.format(':e %s', vim.env.ORG_INBOX)
end

for left, right in pairs(abbreviations) do
  vim.cmd.cnoreabbrev(('%s %s'):format(left, right))
end
