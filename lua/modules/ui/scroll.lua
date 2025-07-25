-- lazy.nvim
return {
  "folke/snacks.nvim",
  opts = function(_, opts)
    opts.scroll = vim.tbl_deep_extend("force", opts.scroll, {
      enabled = vim.g.animation,
      animate = {
        duration = { step = 15, total = vim.g.animation_duration },
        easing = "linear",
      },
      -- faster animation when repeating scroll after delay
      animate_repeat = {
        delay = 100, -- delay in ms before using the repeat animation
        duration = { step = 5, total = 50 },
        easing = "linear",
      },
    })
  end,
}
