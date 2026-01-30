local abbreviations = {
  W = 'w',
  Wa = 'wa',
  WA = 'wa',
  Wq = 'wq',
  WQ = 'wq',
  Q = 'q',
  Qa = 'qa',
  Bd = 'bd',
  E = 'e',
  Tabclose = 'tabclose',
  Tabnew = 'tabnew',
}

for left, right in pairs(abbreviations) do
  vim.cmd.cnoreabbrev(('%s %s'):format(left, right))
end
