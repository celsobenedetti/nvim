local M = {}

M.theme = {
  normal = {
    a = { bg = C.ui.colors.gray, fg = C.ui.colors.black, gui = 'bold' },
    b = { bg = C.ui.colors.lightgray, fg = C.ui.colors.white },
    c = { bg = C.ui.colors.darkgray, fg = C.ui.colors.gray },
  },
  insert = {
    a = { bg = C.ui.colors.blue, fg = C.ui.colors.black, gui = 'bold' },
    b = { bg = C.ui.colors.lightgray, fg = C.ui.colors.white },
    c = { bg = C.ui.colors.lightgray, fg = C.ui.colors.white },
  },
  visual = {
    a = { bg = C.ui.colors.yellow, fg = C.ui.colors.black, gui = 'bold' },
    b = { bg = C.ui.colors.lightgray, fg = C.ui.colors.white },
    c = { bg = C.ui.colors.inactivegray, fg = C.ui.colors.black },
  },
  replace = {
    a = { bg = C.ui.colors.red, fg = C.ui.colors.black, gui = 'bold' },
    b = { bg = C.ui.colors.lightgray, fg = C.ui.colors.white },
    c = { bg = C.ui.colors.black, fg = C.ui.colors.white },
  },
  command = {
    a = { bg = C.ui.colors.green, fg = C.ui.colors.black, gui = 'bold' },
    b = { bg = C.ui.colors.lightgray, fg = C.ui.colors.white },
    c = { bg = C.ui.colors.inactivegray, fg = C.ui.colors.black },
  },
  inactive = {
    a = { bg = C.ui.colors.darkgray, fg = C.ui.colors.gray, gui = 'bold' },
    b = { bg = C.ui.colors.darkgray, fg = C.ui.colors.gray },
    c = { bg = C.ui.colors.darkgray, fg = C.ui.colors.gray },
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
  icon = icon or C.ui.icons.kinds[name:sub(1, 1):upper() .. name:sub(2)]
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
  local path = vim.fn.expand '%:p' --[[@as string]]

  local D = '/' -- Delimiter

  local root_parts = vim.fn.split(root, '/') -- root Parts
  local path_parts = vim.fn.split(path, '/') -- Path Parts

  -- TODO: refactor UI config into directory
  -- TODO: fix hg config
  -- TODO: implement highlighter function util
  vim.api.nvim_set_hl(0, 'LualineCurrentFile', { bg = C.ui.colors.darkgray, fg = C.ui.colors.white, bold = true })
  local highlight = 'LualineCurrentFile'
  local current_file = '%#' .. highlight .. '#' .. path_parts[#path_parts] -- https://github.com/nvim-lualine/lualine.nvim/issues/337#issuecomment-919902020

  if #path_parts == 1 then
    return current_file
  end

  local result = ''
  for i = #root_parts + 1, #path_parts - 1 do
    result = result .. path_parts[i] .. D
  end
  return result .. current_file
end

return M
