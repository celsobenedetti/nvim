--- @param pattern string
local function filter(pattern)
  return { filter = { find = pattern }, opts = { skip = true } }
end

return {
  {
    "folke/noice.nvim",
    opts = function(_, opts)
      opts.routes = vim.list_extend(opts.routes or {}, {
        -- Suppress notifications containing the following patterns
        -- filter("in function '__index'"), -- some md error when moving files
        -- filter(
        --   "method textDocument/documentHighlight is not supported by any of the servers registered for the current buffer "
        -- ), -- likely a LSP thing, encoundered on JSON file
        -- filter("Error executing lua Keyboard interrupt"), -- Looks like a bufferline thing
        -- filter("Error executing vim.schedule lua callback"), -- Neotest error
        -- filter("airbnb"), -- BRO PLEASE STOP 😭
        -- filter("textDocument/diagnostic failed with message"), -- eslint bs
        -- filter("Debug Failure. False expression"), -- BUG: some TS LSP issue 2025-04-02
        -- filter("to exit Nvim"), --  anoying system message "press :qa to exit" bla bla
        -- filter("Attempt to delete a buffer that is in use"), --  showing up when closing capture note in orgmode
        -- filter('Error detected while processing User Autocommands for "VeryLazy":'), -- showing up on notebook
        -- filter("bad argument #1 to 'pairs'"), -- some cmp bug 2025-05-19
        -- filter("[orgmode] No headline found with title'"), -- annoying for my obsidian + orgmode setup
        filter("Can't find file"), -- suppress failed "gf" messages

        -- avante jank
        -- filter 'Error detected while processing', -- some autocmd
        -- filter 'Error executing lua callback: deserialize error: missing field',
      })

      opts.presets = opts.presets or {}
      opts.presets.lsp_doc_border = true
    end,
  },
}
