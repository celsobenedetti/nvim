if os.getenv('PERF') == 'true' then
  vim.g.performance = true
end

---@diagnostic disable-next-line: lowercase-global
map = vim.keymap.set

function Keys(str)
  return vim.api.nvim_replace_termcodes(str, false, false, true)
end

local cwd = require('lib.cwd')
function Explorer()
  if vim.bo.filetype == 'snacks_picker_list' then
    vim.cmd('q')
    return
  end
  Snacks.explorer({
    cwd = cwd.cwd(),
    hidden = cwd.is_current_file_in_repo({ 'dotfiles' }),
    follow_file = true,
  })
  -- Snacks.picker.resume({
  --   source = 'explorer',
  -- })
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
}

vim.g.lazy_nvim_config = {
  performance = {
    rtp = {
      disabled_plugins = {
        'gzip',
        'matchit',
        'matchparen',
        'netrwPlugin',
        'tarPlugin',
        'tohtml',
        'tutor',
        'zipPlugin',
      },
    },
  },
}
