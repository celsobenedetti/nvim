local cwd = require("lib.cwd")
local strings = require("lib.strings")

local M = {}

---@class runner_target
---@field desc string description of the command
---@field title string file title for the terminal
---@field cmd string command to run in the terminal

--- @param targets runner_target[]
local function run_targets(targets)
  -- normalize targets to snacks.picker.finder.Item
  --- @type snacks.picker.finder.Item[]
  local snack_items = {}
  for _, target in ipairs(targets) do
    table.insert(snack_items, {
      text = target.desc,
      file = target.title,
      cmd = target.cmd,
      desc = target.desc,
      preview = {
        ft = "json",
        text = vim.inspect(target),
      },
    })
  end

  Snacks.picker.pick({
    items = snack_items,
    preview = "preview", -- Add this line
    format = function(item, picker)
      return { { item.desc } }
    end,
    confirm = function(picker, item)
      local selected = picker:selected({ fallback = true })

      -- "confirmed" item will not be in the selected, unless manually selected
      local confirmedFound = false

      -- for item in selected
      for _, i in ipairs(selected) do
        M.spawn_term({ title = i.file, cmd = i.cmd, desc = i.desc })

        if i.cmd == item.cmd then
          confirmedFound = true
        end
      end
      if not confirmedFound then
        M.spawn_term({ title = item.title, cmd = item.cmd, desc = item.desc })
      end
      picker:close()
    end,
  })
end

-- read package.json and return scripts section
---@return runner_target[] | nil
local function read_package_json_scripts()
  local package_json = cwd.cwd() .. "/package.json"
  local file = io.open(package_json, "r")
  if not file then
    return nil
  end
  local content = file:read("*all")
  file:close()
  local contents = vim.json.decode(content)

  local scripts = {}
  for k, v in pairs(contents.scripts) do
    table.insert(scripts, {
      desc = k,
      cmd = "pnpm " .. k,
      title = v,
    })
  end
  return scripts
end

--- @return runner_target[] | nil
local function read_justfile_targets()
  local output = vim.fn.system("just --list")
  local err = vim.api.nvim_get_vvar("shell_error") ~= 0
  if err then
    return nil
  end

  --- @type runner_target[]
  local targets = {}

  local skip = true
  for line in output:gmatch("[^\r\n]+") do
    -- skip first line
    if skip then
      skip = false
      goto continue
    end

    line = strings.trim(line)
    line = strings.collapse_whitespace(line)

    local parts = vim.fn.split(line, "#")
    local cmd = strings.trim(parts[1])
    local desc = cmd
    if #parts > 1 then
      desc = cmd .. ":" .. parts[2]
    end

    table.insert(targets, {
      desc = desc,
      cmd = "just " .. cmd,
      title = "just_" .. cmd,
    })
    ::continue::
  end
  return targets
end

--- spawns new tabterm with cmd
---@param term runner_target
M.spawn_term = function(term)
  vim.cmd("tabnew")
  vim.cmd("terminal " .. term.cmd)
  vim.api.nvim_buf_set_name(0, term.title .. ".zsh")
end

-- 1. read targets from Justfile
-- 2. show scripts in snacks.picker
-- 3. spawn_term with selected script
M.run_justfile_target = function()
  local targets = read_justfile_targets()
  if not targets then
    return
  end
  run_targets(targets)
end

-- 1. read scripts from package.json
-- 2. show scripts in snacks.picker
-- 3. spawn_term with selected script
M.run_package_json_script = function()
  local scripts = read_package_json_scripts()
  if not scripts then
    return
  end

  run_targets(scripts)
end

return M
