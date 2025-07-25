-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

vim.keymap.del("n", "<leader>e")
vim.keymap.del("n", "<leader>n")

-- Lazyvim tab management is not to my preference
-- vim.keymap.del("n", "<leader><tab>l")
-- vim.keymap.del("n", "<leader><tab>o")
-- vim.keymap.del("n", "<leader><tab>f")
-- vim.keymap.del("n", "<leader><tab>]")
-- vim.keymap.del("n", "<leader><tab><tab>")
-- vim.keymap.del("n", "<leader><tab>d")
-- vim.keymap.del("n", "<leader><tab>[")
-- -- this is the way:
-- map({ "n", "t" }, "<leader><tab>", ":tabnext<cr>", { desc = "Next Tab" })
-- map({ "n", "t" }, "<leader>tn", ":tabnew %<cr>", { desc = "Send buffer to new tab" })

map("n", "<leader>R", ":e! %<cr>", { desc = "Refresh Buffer" })

-- let me escape insert in terminal!
map("t", "<esc><esc>", "<C-\\><C-n>", { desc = "Escape insert mode in terminal" })

map("n", "ZQ", ":qa!<CR>", { desc = "Quit all" })
map("n", "<leader>on", ":only<CR>", { desc = "':only' alias" })

map("n", "<leader>C", ":Clip<CR>", { desc = "Copy file path to clipboard" })

map("n", "gv", function()
  vim.api.nvim_feedkeys(Keys("<c-w>v"), "n", true)
  Snacks.picker.lsp_definitions()
end, { desc = "Split vertical and go to definition" })

map("n", "gs", function()
  vim.api.nvim_feedkeys(Keys("<c-w>s"), "n", true)
  Snacks.picker.lsp_definitions()
end, { desc = "Split vertical and go to definition" })

map("n", "<leader>B", function()
  local line = vim.fn.getline(".")
  local web_query = require("lib.web").get_search_url_from_query(line)
  if web_query and #web_query > 0 then
    vim.api.nvim_feedkeys("dd", "n", true)
    return vim.ui.open(web_query)
  end

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

map("n", "<leader>mv", require("lib.telescope").mv_file, { desc = "Move file of current buffer to dir" })

local jump = require("lib.jump")
map("n", "k", jump.up)
map("n", "j", jump.down)

map("v", "gx", function()
  local s = require("lib.visual").get_selection()
  local ok, _ = pcall(require("lib.web").search, s or "")
  if ok then
    return
  end
end, { desc = "Search current selected string with google" })

local diagnostic_goto = function(next, severity)
  severity = severity and vim.diagnostic.severity[severity] or nil
  return function()
    vim.diagnostic.jump({
      severity = severity,
      count = next and 1 or -1,
      float = false,
    })
  end
end
map("n", "<leader>cd", vim.diagnostic.open_float, { desc = "Line Diagnostics" })
map("n", "]d", diagnostic_goto(true), { desc = "Next Diagnostic" })
map("n", "[d", diagnostic_goto(false), { desc = "Prev Diagnostic" })
map("n", "]e", diagnostic_goto(true, "ERROR"), { desc = "Next Error" })
map("n", "[e", diagnostic_goto(false, "ERROR"), { desc = "Prev Error" })
map("n", "]w", diagnostic_goto(true, "WARN"), { desc = "Next Warning" })
map("n", "[w", diagnostic_goto(false, "WARN"), { desc = "Prev Warning" })

map("v", "<leader>b", function()
  require("lib.visual").wrap("**", "**")
end, { desc = "bold: wrap selection with **" })

map("v", "<leader>i", function()
  require("lib.visual").wrap("_", "_")
end, { desc = "italic: wrap selection with _" })

map("n", "<leader>t3", require("lib.term").create_3_terms, { desc = "spawn 3 terminals" })

--- runs first set of keys immediately
--- runs second set of keys after delay
---@param key1 string
---@param key2 string
---@param delay number | nil
local function keys_with_delay(key1, key2, delay)
  if delay == nil then
    delay = vim.g.animation_duration or 100
  end
  delay = 1.5 * delay

  return function()
    vim.api.nvim_feedkeys(Keys(key1), "n", true)
    vim.defer_fn(function()
      vim.cmd("normal! " .. key2)
    end, delay)
  end
end

if vim.g.should_center.on_n then
  map("n", "n", keys_with_delay("n", "zz"), { desc = "center on next", noremap = true })
  map("n", "N", keys_with_delay("N", "zz"), { desc = "center on prev", noremap = true })
end

if vim.g.should_center.on_gg then
  map("n", "G", function()
    local count = vim.v.count or 1
    if count > 1 then
      vim.cmd(":" .. count)
      return
    end

    local feed_keys = keys_with_delay("G", "zz", 1.5 * vim.g.animation_duration)
    feed_keys()
  end, { desc = "center on gg", noremap = true })
end

if vim.g.should_center.on_ctrl_d then
  map("n", "<C-d>", keys_with_delay("<C-d>", "zz"), { desc = "center on ctrl-d", noremap = true })
  map("n", "<C-u>", keys_with_delay("<C-u>", "zz"), { desc = "center on ctrl-u", noremap = true })
end
