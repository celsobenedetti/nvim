---@module c.functions.telescope.open_buffers
---
--- A customized version of telescope.builtin.buffers
---
--- This adds a <C-d> mapping to delete the buffer under the cursor

local finders = require 'telescope.finders'
local make_entry = require 'telescope.make_entry'
local action_state = require 'telescope.actions.state'
local pickers = require 'telescope.pickers'
local utils = require 'telescope.utils'
local Path = require 'plenary.path'

local conf = require('telescope.config').values

local function apply_cwd_only_aliases(opts)
  local has_cwd_only = opts.cwd_only ~= nil
  local has_only_cwd = opts.only_cwd ~= nil

  if has_only_cwd and not has_cwd_only then
    -- Internally, use cwd_only
    opts.cwd_only = opts.only_cwd
    opts.only_cwd = nil
  end

  return opts
end

---@return boolean
local function buf_in_cwd(bufname, cwd)
  if cwd:sub(-1) ~= Path.path.sep then
    cwd = cwd .. Path.path.sep
  end
  local bufname_prefix = bufname:sub(1, #cwd)
  return bufname_prefix == cwd
end

local M = {}

M.run = function(opts)
  opts = apply_cwd_only_aliases(opts or {})

  local bufnrs = vim.tbl_filter(function(bufnr)
    if 1 ~= vim.fn.buflisted(bufnr) then
      return false
    end
    -- only hide unloaded buffers if opts.show_all_buffers is false, keep them listed if true or nil
    if opts.show_all_buffers == false and not vim.api.nvim_buf_is_loaded(bufnr) then
      return false
    end
    if opts.ignore_current_buffer and bufnr == vim.api.nvim_get_current_buf() then
      return false
    end

    local bufname = vim.api.nvim_buf_get_name(bufnr)

    if opts.cwd_only and not buf_in_cwd(bufname, vim.loop.cwd()) then
      return false
    end
    if not opts.cwd_only and opts.cwd and not buf_in_cwd(bufname, opts.cwd) then
      return false
    end
    return true
  end, vim.api.nvim_list_bufs())

  if not next(bufnrs) then
    utils.notify('builtin.buffers', { msg = 'No buffers found with the provided options', level = 'INFO' })
    return
  end

  if opts.sort_mru then
    table.sort(bufnrs, function(a, b)
      return vim.fn.getbufinfo(a)[1].lastused > vim.fn.getbufinfo(b)[1].lastused
    end)
  end

  local buffers = {}
  local default_selection_idx = 1
  for _, bufnr in ipairs(bufnrs) do
    local flag = bufnr == vim.fn.bufnr '' and '%' or (bufnr == vim.fn.bufnr '#' and '#' or ' ')

    if opts.sort_lastused and not opts.ignore_current_buffer and flag == '#' then
      default_selection_idx = 2
    end

    local element = {
      bufnr = bufnr,
      flag = flag,
      info = vim.fn.getbufinfo(bufnr)[1],
    }

    if opts.sort_lastused and (flag == '#' or flag == '%') then
      local idx = ((buffers[1] ~= nil and buffers[1].flag == '%') and 2 or 1)
      table.insert(buffers, idx, element)
    else
      table.insert(buffers, element)
    end
  end

  if not opts.bufnr_width then
    local max_bufnr = math.max(unpack(bufnrs))
    opts.bufnr_width = #tostring(max_bufnr)
  end

  pickers
    .new(opts, {
      prompt_title = 'Buffers',
      finder = finders.new_table {
        results = buffers,
        entry_maker = opts.entry_maker or make_entry.gen_from_buffer(opts),
      },
      previewer = conf.grep_previewer(opts),
      sorter = conf.generic_sorter(opts),
      default_selection_index = default_selection_idx,
      attach_mappings = function(_, map)
        map('i', '<C-d>', function(prompt_number)
          local selection = action_state.get_selected_entry()
          local buffnr = selection.bufnr

          -- delete the buffer under the cursor
          vim.api.nvim_buf_delete(buffnr, {})

          local current_picker = action_state.get_current_picker(prompt_number) -- picker state
          local is_last = current_picker.stats.displayed <= 2

          -- "refresh" telescope
          -- close the current picker
          -- call this function again
          vim.api.nvim_buf_delete(0, { force = true })
          if not is_last then
            M.run(opts)
          end
        end)
        return true
      end,
    })
    :find()
end

return M
