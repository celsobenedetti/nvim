---@class LibVisual
local M = {}

local api = vim.api

local function get_visual_selection_region()
  local mode = api.nvim_get_mode().mode
  if mode ~= 'v' and mode ~= 'V' then
    return
  end
  local pos1 = vim.fn.getpos('v')
  local pos2 = vim.fn.getpos('.')
  if pos1[2] == 0 or pos2[2] == 0 then
    return
  end
  local regtype = vim.fn.visualmode()
  local segments = vim.fn.getregionpos(pos1, pos2, {
    type = regtype,
    exclusive = vim.o.selection == 'exclusive',
  })
  if not segments or #segments == 0 then
    return
  end
  local region = {}
  for _, seg in ipairs(segments) do
    local start_pos, end_pos = seg[1], seg[2]
    local lnum = start_pos[2] - 1
    if regtype == 'V' then
      region[lnum] = { 0, -1 }
    else
      region[lnum] = { start_pos[3] - 1, end_pos[3] - 1 }
    end
  end
  local start = { segments[1][1][2] - 1, 0 }
  local finish = { segments[#segments][2][2] - 1, 0 }
  return region, start, finish, mode
end

local function get_text_from_visual_selection(region, start, finish)
  local bufnr = 0
  local lines = api.nvim_buf_get_lines(bufnr, start[1], finish[1] + 1, false)
  local line1_end
  if region[start[1]][2] - region[start[1]][1] < 0 then
    line1_end = #lines[1] - region[start[1]][1]
  else
    line1_end = region[start[1]][2] - region[start[1]][1]
  end
  lines[1] = vim.fn.strpart(lines[1], region[start[1]][1], line1_end)
  if start[1] ~= finish[1] then
    lines[#lines] = vim.fn.strpart(lines[#lines], region[finish[1]][1], region[finish[1]][2] - region[finish[1]][1])
  end
  return table.concat(lines, '\n')
end

local function replace_region_with_text(start, finish, new_lines)
  local bufnr = 0
  api.nvim_buf_set_lines(bufnr, start[1], finish[1] + 1, false, new_lines)
  vim.api.nvim_input('<Esc>')
end

--- get start line, and end line of the visual selection
M.get_region = function()
  local region, start, finish = get_visual_selection_region()
  if not region or not start or not finish then
    return nil, nil
  end
  return tonumber(start[1] + 1), tonumber(finish[1] + 1)
end

M.replace = function(new_text)
  local region, start, finish = get_visual_selection_region()
  if not region or not start or not finish then
    return
  end
  local bufnr = 0
  local lines = api.nvim_buf_get_lines(bufnr, start[1], finish[1] + 1, false)
  if not lines or #lines == 0 then
    return
  end

  -- replace text
  local start_col = region[start[1]][1]
  local end_col = region[finish[1]][2]
  local new_lines = vim.split(new_text, '\n', { plain = true })
  local result_lines = {}
  table.insert(result_lines, lines[1]:sub(1, start_col) .. new_lines[1])
  for i = 2, #new_lines - 1 do
    table.insert(result_lines, new_lines[i])
  end
  if #new_lines > 1 then
    table.insert(result_lines, new_lines[#new_lines] .. lines[#lines]:sub(end_col + 1))
  else
    result_lines[1] = result_lines[1] .. lines[#lines]:sub(end_col + 1)
  end
  replace_region_with_text(start, finish, result_lines)
end

M.get_selection = function()
  local region, start, finish = get_visual_selection_region()
  if not region then
    return
  end
  return get_text_from_visual_selection(region, start, finish)
end

M.wrap = function(pre, post)
  local region, start, finish, mode = get_visual_selection_region()
  if not region or not start or not finish then
    return
  end
  local bufnr = 0
  local lines = api.nvim_buf_get_lines(bufnr, start[1], finish[1] + 1, false)
  if not lines or #lines == 0 then
    return
  end

  if mode == 'V' then
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

  replace_region_with_text(start, finish, lines)
end

return M
