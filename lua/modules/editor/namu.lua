return {
  {
    "bassamsdata/namu.nvim",
    lazy = true,
    keys = {
      { "<leader>ns", "<cmd>Namu symbols<cr>", desc = "Jump to LSP symbol" },
      { "<leader>nw", "<cmd>Namu workspace<cr>", desc = "LSP Symbols - Workspace" },
    },
    config = function()
      require("namu").setup({})
    end,
  },
}
