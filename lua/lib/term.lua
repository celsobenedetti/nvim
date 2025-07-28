local cwd = require("lib.cwd")

local M = {}

---@class term.TabTerm
---@field title string file title for the terminal
---@field cmd string command to run in the terminal

--- spawns list of tab terminals
---@param term term.TabTerm
M.spawn_term = function(term)
  vim.cmd("tabnew")
  vim.cmd("terminal " .. term.cmd)
  vim.api.nvim_buf_set_name(0, term.title)
end

-- read package.json and return scripts section
M.get_scripts = function()
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
      text = k,
      file = v,
      preview = {
        ft = "json",
        text = vim.inspect({ script = k, cmd = v }),
      },
    })
  end
  return scripts
end

-- 1. get scripts from package.json
-- 2. show scripts in snacks.picker
-- 3. spawn_term with selected script
M.pick_package_json_script = function()
  local scripts = M.get_scripts()
  if not scripts then
    return
  end

  -- print(vim.inspect(scripts))

  Snacks.picker.pick({
    items = scripts,
    preview = "preview", -- Add this line
    format = function(item, picker)
      return { { item.text } }
    end,
    confirm = function(picker, item)
      if item then
        M.spawn_term({ title = item.text, cmd = item.file })
      end
      picker:close()
    end,
  })
end

return M
