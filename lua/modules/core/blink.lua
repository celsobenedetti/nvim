if vim.g.completion == nil then
  vim.g.completion = true
end

return {
  'saghen/blink.cmp',
  opts = function(_, opts)
    opts.enabled = function()
      return vim.bo.buftype ~= 'prompt'
        and vim.bo.filetype ~= 'DressingInput'
        and vim.bo.filetype ~= 'OverseerForm'
        and vim.g.completion
    end
    opts.completion = {
      keyword = { range = 'full' },
      menu = {
        border = 'single',
        auto_show = vim.g.completion,
        draw = {
          columns = {
            { 'label', 'label_description', gap = 1 },
            { 'kind_icon', 'kind', gap = 1 },
          },
        },
      },
      documentation = { auto_show = true, window = { border = 'single' } },
    }
  end,
}
