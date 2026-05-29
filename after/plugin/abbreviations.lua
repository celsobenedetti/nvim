local wqa = 'silent! wqa'

local abbreviations = {
  ['in'] = ':e ~/notes/org/inbox.org',
  W = 'w',
  Wa = 'wa',
  WA = 'wa',
  Wq = 'wq',
  WQ = 'wq',
  Wqa = wqa,
  wqa = wqa,
  Q = 'q',
  Qa = 'qa',
  Bd = 'bd',
  E = 'e',
  Tabclose = 'tabclose',
  Tabnew = 'tabnew',
  Set = 'set',
  git = 'Git',
  dif = 'CodeDiff',
  Diff = 'CodeDiff',
  codediff = 'CodeDiff',
  Codediff = 'CodeDiff',
}

for left, right in pairs(abbreviations) do
  vim.cmd.cnoreabbrev(('%s %s'):format(left, right))
end
