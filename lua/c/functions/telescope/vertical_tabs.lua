local M = {}

local pickers = require 'telescope.pickers'
local finders = require 'telescope.finders'
local conf = require('telescope.config').values
local action_state = require 'telescope.actions.state'
local previewers = require 'telescope.previewers'

-- Is entry a markdown file
---@param entry string
---@return boolean
local function is_markdown(entry)
  return string.match(entry, '.md$')
end

--- Vartical tabs is a picker to show files for current directory
--- <c-v> to open file in vertical split
M.run = function(exclude_files)
  exclude_files = exclude_files or {}

  local dir = vim.fn.expand '%:p:h' -- get directory for current file
  local fd = '!fd . --type=file ' .. dir
  local fd_result = vim.api.nvim_exec2(fd, { output = true })
  local dirs = vim.split(fd_result.output, '\n')

  -- remove files already openned as tabs from result set
  dirs = vim.tbl_filter(function(item)
    if #exclude_files > 0 then
      return item ~= '' and not vim.tbl_contains(exclude_files, item) and not string.match(item, '--type=')
    end
    return item ~= '' and not string.match(item, '--type=')
  end, dirs)

  local dirFromHome = string.gsub(dir, vim.env.HOME, '~')
  pickers
    .new({}, {
      prompt_title = dirFromHome .. ' | <C-v> to stack',
      finder = finders.new_table {
        results = dirs,
        entry_maker = function(entry)
          -- remove dir from entry
          local result = {
            value = entry,
            display = string.gsub(entry, dir .. '/', ''),
            ordinal = entry,
          }

          -- if entry is a markdown file
          if is_markdown(entry) then
            result.display = M.get_markdown_title(entry)
          end

          return result
        end,
      },
      previewer = previewers.new_termopen_previewer {
        get_command = function(entry, _)
          if is_markdown(entry.value) then
            return { 'glow', entry.value }
          end

          return { 'bat', '--style', 'numbers,changes', entry.value }
        end,
      },

      sorter = conf.generic_sorter {},
      ---@diagnostic disable-next-line: unused-local
      attach_mappings = function(prompt_bufnr, map)
        map('i', '<C-v>', function()
          local selection = action_state.get_selected_entry()
          local target_file = selection.value

          -- append target_file to exclude_files
          table.insert(exclude_files, target_file)

          -- open target file in vertical split
          vim.cmd 'vsplit'
          vim.cmd('e ' .. target_file)
          M.run(exclude_files)
        end)

        -- actions.select_default:replace(function() end)
        return true
      end,
    })
    :find()
end

M.get_markdown_title = function(filename)
  local file = io.open(filename, 'r')
  if not file then
    return filename
  end

  -- Read the entire file content
  local content = file:read '*all'
  file:close()

  local title = string.match(content, '\n# [% %a%x%p]*\n')
  if not title then
    return filename
  end

  title = string.gsub(title, '# ', '')
  title = string.gsub(title, '\n', '')
  return title
end

return M
