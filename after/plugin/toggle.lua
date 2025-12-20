local M = {}

--- @param msg string
local function notify(msg)
  Snacks.notify.info(msg, { title = 'toggle' })
end

M.completion = function()
  vim.g.completion = not vim.g.completion
  notify(string.format('completion: %q', vim.g.completion))
end

M.supermaven = function()
  vim.cmd('SupermavenToggle')
  notify('toggle: supermaven')
end

M.autoformat = function()
  vim.g.autoformat = not vim.g.autoformat
  notify(string.format('autoformat: %q', vim.g.autoformat))
end

M.statusline_show_position = function()
  vim.g.statusline_show_position = not vim.g.statusline_show_position
end

-- toggles
-- stylua: ignore start
map('n', '<leader>tc', M.completion, { desc = 'toggle: completion' })
map('n', '<leader>ts', M.supermaven, { desc = 'toggle: supermaven' })
map('n', '<leader>tf', M.autoformat, { desc = 'toggle: autoformat' })
map('n', '<leader>tp', M.statusline_show_position, { desc = 'toggle: show position in statusline' })
Snacks.toggle.option("spell", { name = "Spelling" }):map("<leader>us")
Snacks.toggle.option("wrap", { name = "Wrap" }):map("<leader>uw")
Snacks.toggle.option("relativenumber", { name = "Relative Number" }):map("<leader>ur")
Snacks.toggle.diagnostics():map("<leader>ud")
Snacks.toggle.line_number():map("<leader>ul")
Snacks.toggle.option("conceallevel", { off = 0, on = vim.o.conceallevel > 0 and vim.o.conceallevel or 2, name = "Conceal Level" }):map("<leader>uc")
Snacks.toggle.option("showtabline", { off = 0, on = vim.o.showtabline > 0 and vim.o.showtabline or 2, name = "Tabline" }):map("<leader>uA")
Snacks.toggle.treesitter():map("<leader>uT")
Snacks.toggle.option("background", { off = "light", on = "dark" , name = "Dark Background" }):map("<leader>ub")
Snacks.toggle.dim():map("<leader>uD")
Snacks.toggle.animate():map("<leader>ua")
Snacks.toggle.scroll():map("<leader>uS")
Snacks.toggle.indent():map("<leader>ug")
Snacks.toggle.profiler():map("<leader>dpp")
Snacks.toggle.profiler_highlights():map("<leader>dph")
-- stylua: ignore end
