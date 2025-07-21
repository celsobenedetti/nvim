function Augroup(name)
  return vim.api.nvim_create_augroup("Custom_Augroup_" .. name, { clear = true })
end
-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")
--

-- insert mode when entering git commit
vim.api.nvim_create_autocmd("VimEnter", {
  group = Augroup("Git_Commit_Editor"),
  pattern = { "COMMIT_EDITMSG", "new_note" },
  callback = function()
    vim.api.nvim_feedkeys(Keys("i<BS>"), "n", true)
  end,
})

vim.api.nvim_create_autocmd({ "VimEnter" }, {
  callback = function()
    vim.cmd("set formatoptions-=cro") -- Stop comment continuation on line below
  end,
  group = Augroup("Run_on_VimEnter"),
  desc = "Run on all files",
})
