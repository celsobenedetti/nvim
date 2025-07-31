function Augroup(name)
  return vim.api.nvim_create_augroup("celso_augruop_" .. name, { clear = true })
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

-- VimEnter autocmd should fold all
-- BufRead autocmd should fold frontmatter
local markdown_group = Augroup("Markdown")
local markdown = "*.md"
vim.api.nvim_create_autocmd("VimEnter", {
  pattern = markdown,
  group = markdown_group,
  callback = function()
    -- nested markdown folding
    vim.cmd("set foldexpr=NestedMarkdownFolds()")

    vim.defer_fn(function()
      -- fold all
      vim.api.nvim_feedkeys(Keys("zM"), "n", true)

      vim.defer_fn(function()
        -- go do #heading1
        vim.api.nvim_feedkeys(Keys("G"), "n", true)

        vim.defer_fn(function()
          -- unfold it
          vim.api.nvim_feedkeys(Keys("zo"), "n", true)
        end, 60)
      end, 60)
    end, 100)
  end,
})

vim.api.nvim_create_autocmd("BufEnter", {
  pattern = markdown,
  group = markdown_group,
  callback = function()
    vim.defer_fn(function()
      require("lib.markdown").fold_frontmatter()
    end, 100)
  end,
})

vim.api.nvim_create_autocmd("TermOpen", {
  callback = function()
    vim.api.nvim_feedkeys("i", "n", true)
  end,
  group = vim.api.nvim_create_augroup("custom-term-open", { clear = true }),
})
