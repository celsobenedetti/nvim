--- @param pattern string
local function filter(pattern)
  return { filter = { find = pattern }, opts = { skip = true } }
end

return {
  {
    'folke/noice.nvim',
    opts = function(_, opts)
      opts.routes = vim.list_extend(opts.routes or {}, {
        -- Suppress notifications containing the following patterns
        -- filter "Can't find file", -- suppress failed "gf" messages
        -- filter 'Error indecoration provider', -- TreeSitter error when blink renders supermaven completion
        -- filter '_folding_range.lua', -- some error likely related to origami.nvim
      })

      opts.presets = opts.presets or {}
      opts.presets.lsp_doc_border = true
    end,
  },
}
