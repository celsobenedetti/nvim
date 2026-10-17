--- :OrgDo / :OrgDoSearch: hand the heading under the cursor, or an active TODO
--- heading picked from fzf, to a pi agent in a vertical split. Wired up by the
--- nvim-orgmode plugin spec (lua/plugins/secondary/orgmode.lua), the same way
--- <leader>os triggers a lazy load.

---@class LibOrgDo
local M = {}

--- `<file>:<start>:<end>` reference to a headline, tilde-abbreviated like the
--- path `<leader>gy` yanks.
---@param filename string
---@param start_line integer
---@param end_line integer
---@return string
local function location(filename, start_line, end_line)
  return string.format('%s:%d:%d', vim.fn.fnamemodify(filename, ':~'), start_line, end_line)
end

--- Heading under the cursor as an OrgApiHeadline, nil outside an org buffer or
--- above the first heading.
---@return table?
local function headline_at_cursor()
  if vim.bo.filetype ~= 'org' then
    return nil
  end
  local ok, headline = pcall(function()
    return require('orgmode.api').current():get_closest_headline()
  end)
  return ok and headline or nil
end

--- Register :OrgDo and :OrgDoSearch.
function M.setup_commands()
  vim.api.nvim_create_user_command('OrgDo', function()
    local headline = headline_at_cursor()
    if not headline then
      vim.notify('OrgDo: no org heading under the cursor', vim.log.levels.WARN)
      return
    end
    local position = headline.position
    state.pi.launch_task(
      location(vim.api.nvim_buf_get_name(0), position.start_line, position.end_line),
      headline.title
    )
  end, { desc = 'org: launch pi on the heading under the cursor' })

  vim.api.nvim_create_user_command('OrgDoSearch', function()
    lib.org_fzf.search_todo_headings({
      on_confirm = function(item)
        state.pi.launch_task(location(item.filename, item.line_number, item.end_line), item.title)
      end,
    })
  end, { desc = 'org: pick a TODO heading and launch pi on it' })
end

return M
