--- Global options
local M = {
  copilot = true,

  autoformat = true, -- fmt
  completion = true, -- cmp
  diagnostics = true,
  performance = false, -- disable optional/heavy plugins
  hardtime = true,
  winbar = true,

  notes_path = os.getenv 'NOTES',
}

-- iterate and validate all global variables
for key, value in pairs(M) do
  if value == nil or value == '' then
    C.opt.key = ''
    print('WARN global variable not set:', key)
  end
end

M.notes_path = M.notes_path or ''

return M
