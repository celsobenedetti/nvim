local folder_icon = C.UI.icons.kinds.Folder

local M = {}

M.separator = ' %#WinbarSeparator# '

--- Window bar that shows the current file path (in a fancy way).
---@return string
function M.render()
  -- Get the path and expand variables.
  local path = vim.fs.normalize(vim.fn.expand '%:p' --[[@as string]])

  -- Replace slashes by arrows.

  local prefix, prefix_path = '', ''

  -- If the window gets too narrow, shorten the path and drop the prefix.
  if vim.api.nvim_win_get_width(0) < math.floor(vim.o.columns / 3) then
    path = vim.fn.pathshorten(path)
  else
    -- For some special folders, add a prefix instead of the full path (making
    -- sure to pick the longest prefix).
    ---@type table<string, string>
    local special_dirs = {
      NOTES = vim.env.NOTES,
      -- DOTFILES = vim.env.XDG_CONFIG_HOME,
      -- GIT = vim.g.work_projects_dir,
      -- HOME = vim.env.HOME,
      -- PALANTIR = vim.g.work_projects_dir .. '/Palantir',
      -- PERSONAL = vim.g.personal_projects_dir,
    }
    for dir_name, dir_path in pairs(special_dirs) do
      if vim.startswith(path, vim.fs.normalize(dir_path)) and #dir_path > #prefix_path then
        prefix, prefix_path = dir_name, dir_path
      end
    end
    if prefix ~= '' then
      path = path:gsub('^' .. prefix_path, '')
      prefix = string.format('%%#WinBarDir#%s %s%s', folder_icon, prefix, M.separator)
    end
  end

  -- Remove leading slash.
  path = path:gsub('^/', '')

  return table.concat {
    ' ',
    prefix,
    table.concat(
      vim
        .iter(vim.split(path, '/'))
        :map(function(segment)
          return string.format('%%#Winbar#%s', segment)
        end)
        :totable(),
      M.separator
    ),
  } .. M.separator .. require('nvim-navic').get_location()
end

vim.api.nvim_create_autocmd('BufWinEnter', {
  group = vim.api.nvim_create_augroup('mariasolos/winbar', { clear = true }),
  desc = 'Attach winbar',
  callback = function(args)
    if
      not vim.api.nvim_win_get_config(0).zindex -- Not a floating window
      and vim.bo[args.buf].buftype == '' -- Normal buffer
      and vim.api.nvim_buf_get_name(args.buf) ~= '' -- Has a file name
      and not vim.wo[0].diff -- Not in diff mode
    then
      vim.wo.winbar = "%{%v:lua.require'c.modules.ui.winbar.init'.render()%}"
    end
  end,
})

return M
