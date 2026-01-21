-- use `git grep .` to get a list of entries
-- create snacks.picker.finder.Item[] from each entry
-- open Snacks.picker.pick with the list to search through the entries

local M = {}

--- grep dir with git grep
---@param opts {cwd?: string, cmd?: string}
M.git_grep_notes = function(opts)
  opts = opts or {}
  local cmd = opts.cmd or string.format('git -C %s grep --line-number .', opts.cwd or '.')
  local out = vim.system(vim.split(cmd, ' '), { cwd = opts.cwd or '.' })
  local res = out:wait()
  if not res.stdout then
    Snacks.notify('No results found. err: ' .. res.stderr)
    return
  end

  --- @type snacks.picker.Item[]
  local items = {}
  for _, line in ipairs(vim.split(res.stdout, '\n')) do
    local entry = vim.split(line, ':')
    local filepath = table.remove(entry, 1)
    local lineNr = table.remove(entry, 1)

    table.insert(items, {
      text = line,
      line = table.concat(entry, ':'),
      file = filepath,
      lineNr = lineNr,
      pos = { tonumber(lineNr), 0 },
      desc = line,
    })
  end
  Snacks.picker.pick({
    title = 'Git Grep Results for ',
    items = items,
    cwd = opts.cwd or '.',
    layout = 'ivy_split',
  })
end

return M
