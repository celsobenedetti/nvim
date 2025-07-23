local M = {}

local api = vim.api

--- https://github.com/neovim/neovim/pull/13896
---
--- Get the region between two marks and the start and end positions for the region
---
--@param mark1 Name of mark starting the region
--@param mark2 Name of mark ending the region
--@param options Table containing the adjustment function, register type and selection mode
--@return region region between the two marks, as returned by |vim.region|
--@return start (row,col) tuple denoting the start of the region
--@return finish (row,col) tuple denoting the end of the region
local function get_marked_region(mark1, mark2, options)
  local bufnr = 0
  local adjust = options.adjust or function(pos1, pos2)
    return pos1, pos2
  end
  local regtype = options.regtype or vim.fn.visualmode()
  local selection = options.selection or (vim.o.selection ~= "exclusive")

  local pos1 = vim.fn.getpos(mark1)
  local pos2 = vim.fn.getpos(mark2)
  pos1, pos2 = adjust(pos1, pos2)

  local start = { pos1[2] - 1, pos1[3] - 1 + pos1[4] }
  local finish = { pos2[2] - 1, pos2[3] - 1 + pos2[4] }

  -- Return if start or finish are invalid
  if start[2] < 0 or finish[1] < start[1] then
    return
  end

  local region = vim.region(bufnr, start, finish, regtype, selection)
  return region, start, finish
end

--- Get the current visual selection as a string
---
--@return selection string containing the current visual selection
M.get_selection = function()
  local bufnr = 0
  local visual_modes = {
    v = true,
    V = true,
    -- [t'<C-v>'] = true, -- Visual block does not seem to be supported by vim.region
  }

  -- Return if not in visual mode
  if visual_modes[vim.api.nvim_get_mode().mode] == nil then
    return
  end

  local options = {}
  options.adjust = function(pos1, pos2)
    if vim.fn.visualmode() == "V" then
      pos1[3] = 1
      pos2[3] = 2 ^ 31 - 1
    end

    if pos1[2] > pos2[2] then
      pos2[3], pos1[3] = pos1[3], pos2[3]
      return pos2, pos1
    elseif pos1[2] == pos2[2] and pos1[3] > pos2[3] then
      return pos2, pos1
    else
      return pos1, pos2
    end
  end

  local region, start, finish = get_marked_region("v", ".", options)

  -- Compute the number of chars to get from the first line,
  -- because vim.region returns -1 as the ending col if the
  -- end of the line is included in the selection
  local lines = vim.api.nvim_buf_get_lines(bufnr, start[1], finish[1] + 1, false)
  local line1_end
  if region[start[1]][2] - region[start[1]][1] < 0 then
    line1_end = #lines[1] - region[start[1]][1]
  else
    line1_end = region[start[1]][2] - region[start[1]][1]
  end

  lines[1] = vim.fn.strpart(lines[1], region[start[1]][1], line1_end, true)
  if start[1] ~= finish[1] then
    lines[#lines] = vim.fn.strpart(lines[#lines], region[finish[1]][1], region[finish[1]][2] - region[finish[1]][1])
  end
  return table.concat(lines)
end

--- wrap() the current visual selection in given string
---@param pre string to wrap add before the selection
---@param post string to wrap add after the selection
M.wrap = function(pre, post)
  local mode = api.nvim_get_mode().mode
  if not (mode == "v" or mode == "V") then
    return
  end

  local options = {}
  options.adjust = function(pos1, pos2)
    if vim.fn.visualmode() == "V" then
      pos1[3] = 1
      pos2[3] = 2 ^ 31 - 1
    end
    if pos1[2] > pos2[2] then
      pos2[3], pos1[3] = pos1[3], pos2[3]
      return pos2, pos1
    elseif pos1[2] == pos2[2] and pos1[3] > pos2[3] then
      return pos2, pos1
    else
      return pos1, pos2
    end
  end

  local region, start, finish = get_marked_region("v", ".", options)
  if not region then
    return
  end

  local bufnr = 0
  local lines = api.nvim_buf_get_lines(bufnr, start[1], finish[1] + 1, false)
  if not lines or #lines == 0 then
    return
  end

  if mode == "V" then
    lines[1] = pre .. lines[1]
    lines[#lines] = lines[#lines] .. post
  else
    local start_col = region[start[1]][1]
    local end_col = region[finish[1]][2]
    if start[1] == finish[1] then
      local line = lines[1]
      lines[1] = line:sub(1, start_col) .. pre .. line:sub(start_col + 1, end_col) .. post .. line:sub(end_col + 1)
    else
      lines[1] = lines[1]:sub(1, start_col) .. pre .. lines[1]:sub(start_col + 1)
      lines[#lines] = lines[#lines]:sub(1, end_col) .. post .. lines[#lines]:sub(end_col + 1)
    end
  end

  api.nvim_buf_set_lines(bufnr, start[1], finish[1] + 1, false, lines)
  api.nvim_feedkeys(api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)
end

return M
