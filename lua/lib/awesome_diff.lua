--- AwesomeDiff: two-revision diff explorer on top of fugitive.
--- A dedicated tab shows the fugitive `Git diff -p <rev1> <rev2>` patch
--- buffer on top and a quickfix list of changed files below. Each quickfix
--- entry points INTO the patch buffer (at the file's first hunk), so native
--- <CR> scrolling reuses the top window.
---@class LibAwesomeDiff
local M = {}

---Parse unified-diff lines into quickfix items: one per changed file,
---`lnum` = line of the file's first hunk (section header for binary files,
---which have no hunks).
---@param lines string[] lines of a `git diff -p` output buffer
---@param bufnr number buffer the lines belong to
---@return table[] items quickfix items {bufnr, lnum, text}
M.parse_items = function(lines, bufnr)
  local items = {}
  local path, header_lnum = nil, nil
  for i, l in ipairs(lines) do
    local _, new_path = l:match('^diff %-%-git a/(.+) b/(.+)$')
    if new_path then
      -- flush a section that had no hunks (binary file)
      if path then
        items[#items + 1] = { bufnr = bufnr, lnum = header_lnum, text = path }
      end
      path, header_lnum = new_path, i
    elseif l:find('^@@') and path then
      items[#items + 1] = { bufnr = bufnr, lnum = i, text = path }
      path = nil
    end
  end
  if path then
    items[#items + 1] = { bufnr = bufnr, lnum = header_lnum, text = path }
  end
  return items
end

---Open `<rev1>..<rev2>` in a dedicated tab: fugitive patch on top,
---quickfix of changed files below (focused). Completion is tracked through
---fugitive's own async job (fugitive#Result/fugitive#Wait): a non-zero git
---exit status means failure (the error stays visible in the tab), an empty
---patch with status 0 closes the tab again.
---@param rev1 string
---@param rev2 string
M.open = function(rev1, rev2)
  lib.tab.set_next_name(config.icons.git.git .. 'git diff -p ' .. rev1 .. ' ' .. rev2)
  local ok, err = pcall(vim.cmd, ('tab Git diff -p %s %s'):format(rev1, rev2))
  if not ok then
    lib.tab.set_next_name(nil)
    vim.notify('AwesomeDiff: ' .. tostring(err), vim.log.levels.ERROR)
    return
  end

  -- fugitive runs `Git diff` as a job writing into a temp-file buffer. Ask
  -- it for the job state; the fallback covers the entry being reaped before
  -- we look (fast completion).
  local bufnr = vim.api.nvim_win_get_buf(0)
  local result = vim.fn['fugitive#Result'](bufnr)
  if next(result) == nil then
    result = vim.fn['fugitive#Result']()
  end
  if result.job ~= nil then
    vim.fn['fugitive#Wait'](result, 5000)
  end

  local items = M.parse_items(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), bufnr)
  if #items > 0 then
    vim.fn.setqflist({}, ' ', { title = ('AwesomeDiff %s..%s'):format(rev1, rev2), items = items })
    vim.cmd('botright copen')
    return
  end

  if result.exit_status == nil then
    -- Wait timed out (huge diff); leave the tab open for it to finish.
    vim.notify('AwesomeDiff: diff still rendering', vim.log.levels.INFO)
  elseif result.exit_status == 0 then
    vim.cmd('tabclose')
    vim.notify('AwesomeDiff: no changes between ' .. rev1 .. ' and ' .. rev2, vim.log.levels.INFO)
  else
    vim.notify(
      'AwesomeDiff: git exited with ' .. result.exit_status .. '; see the error in the new tab',
      vim.log.levels.WARN
    )
  end
end

return M
