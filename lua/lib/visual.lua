local M = {}

local api = vim.api

local function get_visual_selection_region()
  local mode = api.nvim_get_mode().mode
  if mode ~= "v" and mode ~= "V" then
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
  local bufnr = 0
  local regtype = vim.fn.visualmode()
  local selection = vim.o.selection ~= "exclusive"
  local pos1 = vim.fn.getpos("v")
  local pos2 = vim.fn.getpos(".")
  pos1, pos2 = options.adjust(pos1, pos2)
  local start = { pos1[2] - 1, pos1[3] - 1 + pos1[4] }
  local finish = { pos2[2] - 1, pos2[3] - 1 + pos2[4] }
  if start[2] < 0 or finish[1] < start[1] then
    return
  end
  local region = vim.region(bufnr, start, finish, regtype, selection)
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
  return table.concat(lines)
end

local function replace_region_with_text(start, finish, new_lines)
  local bufnr = 0
  api.nvim_buf_set_lines(bufnr, start[1], finish[1] + 1, false, new_lines)
  api.nvim_feedkeys(api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)
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

  replace_region_with_text(start, finish, lines)
end

return M
