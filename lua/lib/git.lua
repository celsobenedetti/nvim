--- @class LibGit
--- Git actions shared by keymaps, so the same flow can run against the
--- current buffer or against an arbitrary path: `ga` in a normal buffer
--- (after/plugin/git.lua) and `ga` on the file section under the cursor in a
--- `:Diff` patch buffer (after/ftplugin/git.lua) both call M.add.
local M = {}

---@param level 'info' | 'warn' | 'error'
---@param msg string
local function notify(level, msg)
  Snacks.notify[level](msg, { title = 'Git', icon = '', style = 'fancy' })
end

---Work-tree root of the repo containing `dir`, or nil when there is none.
---Shared with the patch-buffer actions in lib.Diff: the `diff --git` paths a
---patch yields are root-relative, so they need this to become real paths.
---@param dir string
---@return string?
M.root = function(dir)
  local result = vim.system({ 'git', '-C', dir, 'rev-parse', '--show-toplevel' }):wait()
  if result.code ~= 0 then
    return nil
  end
  local root = (result.stdout or ''):gsub('%s+$', '')
  return root ~= '' and root or nil
end

---Stage `file` the way `ga` always has: an untracked file is added wholesale
---(`git add`), a tracked file with unstaged changes opens fugitive's
---interactive `Git add -p` in a vertical split, and anything else (clean, or
---only staged changes) just warns. The state comes from `git status`, not
---gitsigns, so it works for files that aren't in a buffer at all.
---@param file? string path to stage; defaults to the current buffer's file.
---  A relative path resolves against the work-tree root of the cwd — the
---  `diff --git` paths a patch buffer yields are root-relative.
M.add = function(file)
  if not file or file == '' then
    if vim.bo.buftype ~= '' then
      notify('warn', 'not a git file')
      return
    end
    file = vim.api.nvim_buf_get_name(0)
    if file == '' then
      notify('warn', 'buffer has no file')
      return
    end
  end

  local absolute = file:sub(1, 1) == '/'
  local root = M.root(absolute and vim.fs.dirname(file) or vim.fn.getcwd())
  if not root then
    notify('warn', 'not a git repo')
    return
  end
  local abs = absolute and file or (root .. '/' .. file)
  local rel = vim.startswith(abs, root .. '/') and abs:sub(#root + 2) or abs

  -- `-uall` so an untracked file inside an untracked directory reports as
  -- itself (`?? dir/file`) rather than as the collapsed directory.
  local status = vim.system({ 'git', '-C', root, 'status', '--porcelain', '-uall', '--', abs }):wait()
  if status.code ~= 0 then
    notify('error', string.format('git status failed: `%s`', rel))
    return
  end

  -- XY: X = index, Y = work tree. `??` is untracked; any non-space Y means
  -- there is something unstaged to pick hunks from.
  local xy = ((status.stdout or ''):match('^[^\n]*') or ''):sub(1, 2)

  if xy == '??' then
    local added = vim.system({ 'git', '-C', root, 'add', '--', abs }):wait()
    if added.code ~= 0 then
      notify('error', string.format('git add failed: `%s`', rel))
      return
    end
    notify('info', string.format('Added: `%s`', rel))
    return
  end

  if xy:sub(2, 2) == ' ' or xy == '' then
    notify('warn', string.format('No changes: `%s`', rel))
    return
  end

  vim.cmd('vertical Git add -p -- ' .. vim.fn.fnameescape(abs))
end

return M
