local M = {}

M.theme = {
  normal = {
    a = { bg = C.UI.colors.gray, fg = C.UI.colors.black, gui = 'bold' },
    b = { bg = C.UI.colors.lightgray, fg = C.UI.colors.white },
    c = { bg = C.UI.colors.darkgray, fg = C.UI.colors.gray },
  },
  insert = {
    a = { bg = C.UI.colors.blue, fg = C.UI.colors.black, gui = 'bold' },
    b = { bg = C.UI.colors.lightgray, fg = C.UI.colors.white },
    c = { bg = C.UI.colors.lightgray, fg = C.UI.colors.white },
  },
  visual = {
    a = { bg = C.UI.colors.yellow, fg = C.UI.colors.black, gui = 'bold' },
    b = { bg = C.UI.colors.lightgray, fg = C.UI.colors.white },
    c = { bg = C.UI.colors.inactivegray, fg = C.UI.colors.black },
  },
  replace = {
    a = { bg = C.UI.colors.red, fg = C.UI.colors.black, gui = 'bold' },
    b = { bg = C.UI.colors.lightgray, fg = C.UI.colors.white },
    c = { bg = C.UI.colors.black, fg = C.UI.colors.white },
  },
  command = {
    a = { bg = C.UI.colors.green, fg = C.UI.colors.black, gui = 'bold' },
    b = { bg = C.UI.colors.lightgray, fg = C.UI.colors.white },
    c = { bg = C.UI.colors.inactivegray, fg = C.UI.colors.black },
  },
  inactive = {
    a = { bg = C.UI.colors.darkgray, fg = C.UI.colors.gray, gui = 'bold' },
    b = { bg = C.UI.colors.darkgray, fg = C.UI.colors.gray },
    c = { bg = C.UI.colors.darkgray, fg = C.UI.colors.gray },
  },
}

---@return {fg?:string}?
function M.fg(name)
  local hl = vim.api.nvim_get_hl(0, { name = name, link = false })
  local fg = hl and hl.fg or hl.foreground
  return fg and { fg = string.format('#%06x', fg) } or nil
end

---@param icon string
---@param status fun(): nil|"ok"|"error"|"pending"
function M.status(icon, status)
  local colors = {
    ok = 'Special',
    error = 'DiagnosticError',
    pending = 'DiagnosticWarn',
  }
  return {
    function()
      return icon
    end,
    cond = function()
      return status() ~= nil
    end,
    color = function()
      return M.fg(colors[status()] or colors.ok)
    end,
  }
end
---
---@param name string
---@param icon? string
function M.cmp_source(name, icon)
  icon = icon or C.UI.icons.kinds[name:sub(1, 1):upper() .. name:sub(2)]
  local started = false
  return M.status(icon, function()
    if not package.loaded['cmp'] then
      return
    end
    for _, s in ipairs(require('cmp').core.sources or {}) do
      if s.name == name then
        if s.source:is_available() then
          started = true
        else
          return started and 'error' or nil
        end
        if s.status == s.SourceStatus.FETCHING then
          return 'pending'
        end
        return 'ok'
      end
    end
  end)
end

---@param name string
function M.add_cmp_source(name)
  return {
    'nvim-lualine/lualine.nvim',
    optional = true,
    event = 'VeryLazy',
    opts = function(_, opts)
      table.insert(opts.sections.lualine_x, 2, M.cmp_source(name))
    end,
  }
end

function M.pretty_path()
  local root = vim.fs.root(0, '.git') or vim.uv.cwd() --[[@as string]]
  local full_path = vim.fn.expand '%:p' --[[@as string]]

  local D = '/' -- Delimiter
  local E = C.UI.icons.chars.ellipsis -- Elipsis

  local path = full_path:gsub(root .. '/', '') -- remove the root from the path

  local p = vim.fn.split(path, '/') -- Path Parts
  local highlight = 'LualineCurrentFile'
  local current_file = '%#' .. highlight .. '#' .. p[#p] -- https://github.com/nvim-lualine/lualine.nvim/issues/337#issuecomment-919902020

  if #p == 1 then
    return current_file
  end

  if #p > 4 and #path > 50 then
    p[1] = string.sub(p[1], 1, 1) .. E
  end

  if #path < 50 then
    local result = ''
    for i = 1, #p - 1 do
      result = result .. p[i] .. D
    end
    return result .. current_file
  end

  local dominant_index = 2
  if C.CWD.is_work() then
    if path:find 'nestjs' then
      dominant_index = 3
    end
  end

  if #path < 100 then
    return p[1] .. D .. p[dominant_index] .. D .. E .. D .. p[#p - 1] .. D .. current_file
  end

  if #p > 5 then
    return string.sub(p[1], 1, 4) .. D .. E .. D .. p[dominant_index] .. D .. E .. D .. p[#p - 1] .. D .. current_file
  end

  return path
end

return M
