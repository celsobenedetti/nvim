if os.getenv('PERF') == 'true' then
  vim.g.performance = true
end

---@diagnostic disable-next-line: lowercase-global
map = vim.keymap.set

function Keys(str)
  return vim.api.nvim_replace_termcodes(str, false, false, true)
end

function Explorer()
  if vim.bo.filetype == 'snacks_picker_list' then
    vim.cmd('q')
    return
  end
  Snacks.picker.resume({ source = 'explorer' })
end

---@class Options
---@field newtab? boolean opens terminal in new tab
---@param cmd? string
---@param opts? Options
function Terminal(cmd, opts)
  local term = 'terminal'
  if opts ~= nil and opts.newtab then
    term = 'tab term'
  end
  if type(cmd) == 'string' and #cmd > 0 then
    term = term .. ' ' .. cmd
  end
  vim.cmd(term)
  vim.cmd('startinsert')
end
