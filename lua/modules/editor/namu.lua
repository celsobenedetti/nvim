return {
  {
    "bassamsdata/namu.nvim",
    config = function()
      require("namu").setup({})

      -- === Suggested Keymaps: ===
      vim.keymap.set("n", "<leader>ns", ":Namu symbols<cr>", {
        desc = "Jump to LSP symbol",
        silent = true,
      })
      vim.keymap.set("n", "<leader>nw", ":Namu workspace<cr>", {
        desc = "LSP Symbols - Workspace",
        silent = true,
      })
    end,
  },
}
