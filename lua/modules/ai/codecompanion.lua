return {
  {
    "olimorris/codecompanion.nvim",
    keys = {
      { "<leader>cca", "<cmd>CodeCompanionActions<cr>", desc = "CodeCompanion actions", mode = { "n", "v" } },
      { "<leader>ccc", "<cmd>CodeCompanionChat<cr>", desc = "CodeCompanion chat", mode = { "n", "v" } },
    },
    config = function()
      require("codecompanion").setup({
        opts = {
          system_prompt = function(opts)
            return require("lib.ai").the_engineer()
          end,
        },
        adapters = {
          openai = function()
            return require("codecompanion.adapters").extend("openai", {
              schema = {
                model = {
                  default = "gpt-4.1",
                },
              },
            })
          end,
        },
        strategies = {
          chat = { adapter = "openai" },
          inline = { adapter = "openai" },
          cmd = { adapter = "openai" },
        },
      })
    end,

    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
  },
}
