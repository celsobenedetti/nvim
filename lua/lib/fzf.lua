--- search entries with fzf-lua
--- runs the command once and fuzzy-filters the results in fzf (like the
--- Snacks static-item picker), with native file:line preview and jump.
---@param opts {cwd?: string, cmd?: string[]}
return function(opts)
  opts = opts or {}
  local cmd = opts.cmd or { 'git', '-C', '%s', 'grep', '--line-number', '.', opts.cwd or '.' }

  local parts = {}
  for _, arg in ipairs(cmd) do
    parts[#parts + 1] = vim.fn.shellescape(arg)
  end

  require('fzf-lua').grep({
    raw_cmd = table.concat(parts, ' '),
    cwd = opts.cwd,
    profile = 'ivy',
    winopts = { title = 'grep ' .. (opts.cwd or '') },
  })
end
