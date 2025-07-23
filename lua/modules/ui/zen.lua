return {

  "folke/snacks.nvim",
  opts = function(_, opts)
    Snacks.toggle.dim():map("<leader>tw")

    Snacks.config.style("zen", {
      enter = true,
      fixbuf = false,
      minimal = false,
      width = 120,
      height = 0,
      backdrop = { transparent = false, blend = 99 },
      keys = { q = false },
      zindex = 40,
      wo = {
        winhighlight = "NormalFloat:Normal",
      },
      w = {
        snacks_main = true,
      },
    })
  end,
}
