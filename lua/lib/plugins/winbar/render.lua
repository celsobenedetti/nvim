---@module PORQUE MARIA
---@author MariaSolOS
---@reference  https://github.com/MariaSolOs/dotfiles/blob/f77169cd0622a5893aa47163395d4ddc5ed49290/.config/nvim/lua/winbar.lua

local M = {}

--- Window bar that shows the current file path (in a fancy way).
---@return string
function M.render()
  local root = vim.fs.root(0, '.git') --[[@as string]]
  local full_path = vim.fn.expand '%:p' --[[@as string]]
  local path = full_path:gsub(root .. '/', '') -- remove the root from the path

  local current_file = path:match '.+/(.+)$' or path
  local file_extension = current_file:match '%.([^%.]+)$' or ''

  local icon = require('nvim-web-devicons').get_icon(current_file, file_extension)

  -- Replace slashes by arrows.
  local separator = ' %#WinBarSeparator# '

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
      prefix = string.format('%%#WinBarDir#%s %s%s', C.UI.icons.kinds.Folder, prefix, separator)
    end
  end

  -- Remove leading slash.
  path = path:gsub('^/', '')

  local has_navic, navic = pcall(require, 'nvim-navic')

  local result = table.concat {
    ' ',
    prefix,
    table.concat(
      vim
        .iter(vim.split(path, '/'))
        :map(function(segment)
          if segment == current_file then
            return string.format('%%#LualineCurrentFile#%s', icon .. ' ' .. segment)
          end

          return string.format('%%#WinBar#%s', segment)
        end)
        :totable(),
      separator
    ),
  }

  if has_navic then
    result = result .. separator .. navic.get_location()
  end

  return result
end

return M
