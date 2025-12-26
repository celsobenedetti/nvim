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

vim.g.fn = {
  ---@param name? string
  rename_tab = function(name)
    local ok, tabby = pcall(require, 'tabby')
    if not ok then
      Snacks.notify.warn("can't rename tab: tabby.nvim not installed")
      return
    end
    if name and #name > 0 then
      tabby.tab_rename(name)
      return
    end
    vim.ui.input({ prompt = 'rename Tab: ' }, function(input)
      require('tabby').tab_rename(input)
    end)
  end,
  cr = function()
    if vim.bo.filetype == 'markdown' then
      require('obsidian.api').smart_action()
      return
    end
    if vim.bo.filetype == 'org' then
      local ok, orgmode = pcall(require, 'orgmode')
      if ok then
        orgmode.action('org_mappings.open_at_point')
      end
      return
    end
    vim.api.nvim_feedkeys(Keys('<CR>'), 'n', true)
  end,
}

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
