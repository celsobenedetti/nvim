-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

vim.keymap.del("n", "<leader>e")

map("n", "<leader>C", ":Clip<CR>", { desc = "Copy file path to clipboard" })

local telescope = require("lib.telescope")
map("n", "<leader>mv", telescope.mv_file, { desc = "Move file of current buffer to dir" })
map("n", "<leader>of", telescope.org_files, { desc = "Search Org files" })
