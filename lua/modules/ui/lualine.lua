return {
  "nvim-lualine/lualine.nvim",
  opts = function(_, opts)
    opts.opts = vim.tbl_deep_extend("force", opts.opts or {}, {

      theme = {
        terminal = { fg = "#ffffff", bg = "#000000" }, -- Example: White text on black background
      },
    })
  end,
}
