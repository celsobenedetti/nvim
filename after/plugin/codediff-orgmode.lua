local M = {}

local function buf_get_var(bufnr, name)
  local ok, val = pcall(vim.api.nvim_buf_get_var, bufnr, name)
  return ok and val
end

local function clear_orgmode_extmarks(bufnr)
  local ns = vim.api.nvim_get_namespaces()['org_custom_highlighter']
  if ns and vim.api.nvim_buf_is_valid(bufnr) then
    vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
  end
end

function M.patch()
  local ok, OrgHighlighter = pcall(require, 'orgmode.colors.highlighter')
  if not ok then
    return
  end

  local original_on_win = OrgHighlighter._on_win
  OrgHighlighter._on_win = function(self, ns, win, bufnr, topline, botline)
    local ok, diff = pcall(function()
      return vim.wo[win].diff
    end)
    if (ok and diff) or buf_get_var(bufnr, 'codediff_active') then
      return false
    end
    return original_on_win(self, ns, win, bufnr, topline, botline)
  end
end

--- Guard orgmode's tree-sitter predicate so it doesn't crash on string sources
--- (codediff uses string parsers for inline syntax highlighting, which passes
---  the source string instead of a buffer number to predicates).
function M.guard_predicates()
  local ok = pcall(function()
    vim.treesitter.query.add_predicate('org-hide-leading-stars?', function(_, _, source)
      if type(source) ~= 'number' or not vim.api.nvim_buf_is_valid(source) then
        return false
      end
      local ok, config = pcall(require, 'orgmode.config')
      return ok and config:hide_leading_stars(source)
    end, { force = true, all = true })
  end)
  if not ok then
    vim.notify('codediff-orgmode: failed to guard tree-sitter predicate', vim.log.levels.WARN)
  end
end

local function mark_buffers(tabpage)
  if not vim.api.nvim_tabpage_is_valid(tabpage) then
    return
  end
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tabpage)) do
    local bufnr = vim.api.nvim_win_get_buf(win)
    if vim.api.nvim_buf_is_valid(bufnr) then
      vim.api.nvim_buf_set_var(bufnr, 'codediff_active', true)
      clear_orgmode_extmarks(bufnr)
    end
  end
end

local function unmark_buffers(tabpage)
  if not vim.api.nvim_tabpage_is_valid(tabpage) then
    return
  end
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tabpage)) do
    local bufnr = vim.api.nvim_win_get_buf(win)
    if vim.api.nvim_buf_is_valid(bufnr) then
      pcall(vim.api.nvim_buf_del_var, bufnr, 'codediff_active')
    end
  end
end

vim.api.nvim_create_autocmd('FileType', {
  pattern = 'org',
  once = true,
  callback = function()
    M.patch()
    M.guard_predicates()
  end,
})

vim.api.nvim_create_autocmd('User', {
  pattern = 'CodeDiffOpen',
  callback = function(args)
    if args.data and args.data.tabpage then
      mark_buffers(args.data.tabpage)
    end
  end,
})

vim.api.nvim_create_autocmd('User', {
  pattern = 'CodeDiffClose',
  callback = function(args)
    if args.data and args.data.tabpage then
      unmark_buffers(args.data.tabpage)
    end
  end,
})

return M
