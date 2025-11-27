--- @param pattern string
local function filter(pattern)
  return { filter = { find = pattern }, opts = { skip = true } }
end

return {
  {
    'folke/noice.nvim',
    enabled = vim.g.noice,
    opts = function(_, opts)
      opts.routes = vim.list_extend(opts.routes or {}, {
        -- Suppress notifications containing the following patterns
        filter 'position_encoding param is required',
      })

      opts.presets = opts.presets or {}
      opts.presets.lsp_doc_border = true
    end,
  },
}
