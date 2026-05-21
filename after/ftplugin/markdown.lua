local function fold_frontmatter()
  vim.schedule(function()
    local has_frontmatter = vim.api.nvim_buf_get_lines(0, 0, -1, false)[1]:match('^---')
    if not has_frontmatter then
      return
    end

    local lines = vim.api.nvim_buf_get_lines(0, 1, -1, false)
    local end_of_frontmatter = 1

    for i, line in ipairs(lines) do
      if line:match('^---') then
        end_of_frontmatter = i + 1
        break
      end
    end

    vim.opt.foldmethod = 'manual'
    vim.api.nvim_command('1,' .. end_of_frontmatter .. 'fold')
  end)
end

-- create custom highlight group for markdown #tags
-- namespace code to ensure higlights only apply to markdown windows, even after markdown ftplugin is loaded
local function highlight_tags()
  local ns = vim.api.nvim_create_namespace('ft_markdown_local_hl')
  vim.cmd('syntax match MarkdownTag /#[a-zA-Z0-9_-]\\+/')
  vim.api.nvim_set_hl(ns, 'MarkdownTag', { link = 'BlinkCmpScrollBarThumb' })

  -- apply highlight namespace only for markdown windows
  local bufnr = vim.api.nvim_get_current_buf()
  local group = vim.api.nvim_create_augroup('markdown_local_hl_' .. bufnr, { clear = true })

  local function apply_ns()
    local ok = pcall(vim.api.nvim_win_set_hl_ns, 0, ns)
    if not ok and vim.api.nvim_set_hl_ns then
      pcall(vim.api.nvim_set_hl_ns, ns)
    end
  end

  local function reset_ns()
    local ok = pcall(vim.api.nvim_win_set_hl_ns, 0, 0)
    if not ok and vim.api.nvim_set_hl_ns then
      pcall(vim.api.nvim_set_hl_ns, 0)
    end
  end

  vim.api.nvim_create_autocmd('BufWinEnter', {
    buffer = bufnr,
    group = group,
    callback = apply_ns,
  })

  vim.api.nvim_create_autocmd('BufWinLeave', {
    buffer = bufnr,
    group = group,
    callback = reset_ns,
  })
  -- set for the current window now
  apply_ns()
end

--- main execution

vim.opt.wrap = true -- disable wrap

-- follow wiki links with enter (only in notes dir)
local notes = vim.g.env and vim.g.env.notes
if notes then
  local filepath = vim.fn.expand('%:p')
  if filepath:find(notes.NOTES, 1, true) == 1 or filepath:find(notes.ZK, 1, true) == 1 then
    vim.keymap.set('n', '<CR>', function()
      local line = vim.api.nvim_get_current_line()
      local col = vim.api.nvim_win_get_cursor(0)[2]
      if line:sub(1, col + 1):find('[[', 1, true) and line:sub(col + 2):find(']]', 1, true) then
        pcall(function()
          require('obsidian').open()
        end)
        return
      end
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<CR>', true, false, true), 'n', false)
    end, { buffer = true, desc = 'follow link' })
  end
end

vim.schedule(fold_frontmatter)
vim.schedule(highlight_tags)
