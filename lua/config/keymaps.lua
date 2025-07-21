-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

vim.keymap.del("n", "<leader>e")
vim.keymap.del("n", "<leader>n")

map("n", "<leader>re", ":e! %<cr>", { desc = "Refresh Buffer" })

map("n", "<leader><tab>", ":tabnext<cr>", { desc = "Next Tab" })
map("n", "<leader>tn", ":tabnew<cr>", { desc = "New Tab (:tabnew)" })
map("n", "ZQ", ":qa!<CR>", { desc = "Quit all" })
map("n", "<leader>on", ":only<CR>", { desc = "':only' alias" })

map("n", "<leader>C", ":Clip<CR>", { desc = "Copy file path to clipboard" })

local telescope = require("lib.telescope")
map("n", "<leader>mv", telescope.mv_file, { desc = "Move file of current buffer to dir" })
map("n", "<leader>of", telescope.org_files, { desc = "Search Org files" })
map("n", "<leader>fn", telescope.notes, { desc = "Search Notes" })

map("n", "gv", function()
  vim.api.nvim_feedkeys(Keys("<c-w>v"), "n", true)
  Snacks.picker.lsp_definitions()
end, { desc = "Split vertical and go to definition" })

map("n", "gs", function()
  vim.api.nvim_feedkeys(Keys("<c-w>s"), "n", true)
  Snacks.picker.lsp_definitions()
end, { desc = "Split vertical and go to definition" })

map("n", "<leader>B", function()
  vim.api.nvim_feedkeys(Keys("V!bash<CR>"), "n", true)
end, { desc = "Run current line as bash command" })

map("v", "<leader>B", function()
  vim.api.nvim_feedkeys(Keys("!bash<CR>"), "n", true)
end, { desc = "Run current line as bash command" })

-- run current line as lua command in vim
map({ "n", "v" }, "<leader>L", function()
  local current_line = vim.fn.getline(".")
  vim.api.nvim_feedkeys(Keys(":lua " .. current_line .. "<CR>"), "n", true)
end, { desc = "Run current line as vim command" })

map("n", "<leader>P", function()
  vim.api.nvim_feedkeys(Keys("vip"), "n", true)
  local file_path = vim.fn.expand("%:p")
  if file_path:find("html") then
    vim.api.nvim_feedkeys(Keys("!prettier --parser=html<CR>"), "n", true)
  else
    vim.api.nvim_feedkeys(Keys("!prettier --parser=markdown<CR>"), "n", true)
  end
end, { desc = "Format current paragraph with Prettier" })

map("v", "<leader>P", function()
  local file_path = vim.fn.expand("%:p")
  if file_path:find(".md") then
    vim.api.nvim_feedkeys(Keys("!prettier --parser=markdown<CR>"), "n", true)
  else
    vim.api.nvim_feedkeys(Keys("!prettier --parser=html<CR>"), "n", true)
  end
end, { desc = "Format current selection with Prettier" })

map("n", "<leader>rm", function()
  vim.api.nvim_feedkeys(Keys(":!rm %<CR>"), "n", true)
  vim.api.nvim_feedkeys(Keys(":bdelete<cr>"), "n", true)
end, { desc = "rm buffer file" })

map("n", "<leader>e", vim.diagnostic.open_float, { desc = "LSP: Line Diagnostics" })
