local function fold_frontmatter()
  vim.schedule(function()
    local has_frontmatter = vim.api.nvim_buf_get_lines(0, 0, -1, false)[1]:match('^---')
    if not has_frontmatter then
      return
    end

    vim.opt.foldmethod = 'manual'

    local lines = vim.api.nvim_buf_get_lines(0, 1, -1, false)
    local end_of_frontmatter = 1

    for i, line in ipairs(lines) do
      if line:match('^---') then
        end_of_frontmatter = i + 1
        break
      end
    end

    vim.api.nvim_command('1,' .. end_of_frontmatter .. 'fold')
  end)
end

-- VimEnter autocmd should fold all
-- BufRead autocmd should fold frontmatter
local markdown_group = vim.api.nvim_create_augroup('Markdown', { clear = true })
local markdown = '*.md'
vim.api.nvim_create_autocmd('BufEnter', {
  desc = 'Fold frontmatter when entering markdown file',
  pattern = markdown,
  group = markdown_group,
  callback = function()
    vim.schedule(fold_frontmatter)
  end,
})
