local wqa = 'silent! wqa'

local abbreviations = {
  W = 'w',
  Wa = 'wa',
  WA = 'wa',
  Wq = 'wq',
  WQ = 'wq',
  Wqa = wqa,
  -- wqa = wqa,
  Q = 'q',
  Qa = 'qa',
  Bd = 'bd',
  E = 'e',
  Tabclose = 'tabclose',
  Tabnew = 'tabnew',
  Set = 'set',
  git = 'Git',
  commit = 'tab Git commit',
  dif = 'CodeDiff',
  Diff = 'CodeDiff',
  codediff = 'CodeDiff',
  Codediff = 'CodeDiff',
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
