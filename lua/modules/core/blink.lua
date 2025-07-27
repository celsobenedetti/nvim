return {
  "saghen/blink.cmp",
  opts = function(_, opts)
    opts.enabled = function()
      return vim.bo.buftype ~= "prompt" and vim.bo.filetype ~= "DressingInput" and vim.b.completion ~= false
    end
    opts.completion = {
      keyword = { range = "full" },
      menu = {
        border = "single",
        auto_show = true,
        draw = {
          columns = {
            { "label", "label_description", gap = 1 },
            { "kind_icon", "kind", gap = 1 },
          },
        },
      },
      documentation = { auto_show = true, window = { border = "single" } },
    }
  end,
}
