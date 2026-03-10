local M = {}

--- @param fn function? to be called after tab is created or focus
M.focus_or_create_notes_tab = function(fn)
  local tab_id = -1
  local has_tabby, tab_name = pcall(require, 'tabby.feature.tab_name')
  if has_tabby then
    local tabs = vim.api.nvim_list_tabpages()
    for _, tab in ipairs(tabs) do
      if tab_name.get(tab):find(vim.g.notes_tabname) then
        tab_id = tab
      end
    end
  end

  if tab_id == -1 then
    vim.cmd('tabnew')
    vim.g.fn.rename_tab(vim.g.notes_tabname)
    vim.cmd('lcd ' .. vim.g.env.notes.NOTES)
  else
    vim.api.nvim_set_current_win(vim.api.nvim_tabpage_get_win(tab_id))
  end

  if fn then
    vim.schedule(fn)
  end
end

--- grep directory, search entries with picker
---@param opts {cwd?: string, cmd?: string[]}
M.grep = function(opts)
  opts = opts or {}
  local cmd = opts.cmd or { 'git', '-C', '%s', 'grep', '--line-number', '.', opts.cwd or '.' }
  local out = vim.system(cmd)
  local res = out:wait()
  if not res.stdout or res.stdout == '' or #res.stderr > 0 then
    Snacks.notify('No results found. err: ' .. res.stderr)
    return
  end

  -- - @type snacks.picker.Item[]
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
    title = 'grep notes',
    items = items,
    cwd = opts.cwd or '.',
    layout = 'ivy_split',
  })
end

return M
