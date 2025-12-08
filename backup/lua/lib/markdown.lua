local M = {}

M.fold_frontmatter = function()
  vim.schedule(function()
    local has_frontmatter = vim.api.nvim_buf_get_lines(0, 0, -1, false)[1]:match '^---'
    if not has_frontmatter then
      return
    end

    vim.opt.foldmethod = 'manual'

    local lines = vim.api.nvim_buf_get_lines(0, 1, -1, false)
    local end_of_frontmatter = 1

    for i, line in ipairs(lines) do
      if line:match '^---' then
        end_of_frontmatter = i + 1
        break
      end
    end

    vim.api.nvim_command('1,' .. end_of_frontmatter .. 'fold')
  end)
end

return M
