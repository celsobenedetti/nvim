local M = {}

--- if in column 0,  fold with `zc`
--- else, simply press `h` in normal mode
M.h = function()
  local col = vim.api.nvim_win_get_cursor(0)[2] + 1
  if col == 1 then
    vim.cmd 'normal! zc'
  else
    vim.cmd 'normal! h'
  end
end

-- if has fold, unfold with `zo`
-- then press `l` in normal mode
M.l = function()
  if vim.fn.foldclosed '.' ~= -1 then
    vim.cmd 'normal! zo'
  end
  vim.cmd 'normal! l'
end

return M
