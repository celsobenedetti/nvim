--- @param pattern string
local function filter_pattern(pattern)
  return { filter = { find = pattern }, opts = { skip = true } }
end

return {
  {
    'folke/noice.nvim',
    event = 'VeryLazy',
    lazy = C.Globals.performance,
    opts = {
      lsp = {
        signature = { auto_open = false },
        override = {
          ['vim.lsp.util.convert_input_to_markdown_lines'] = true,
          ['vim.lsp.util.stylize_markdown'] = true,
          ['cmp.entry.get_documentation'] = true,
        },
      },
      routes = {
        {
          filter = {
            event = 'msg_show',
            any = {
              { find = '%d+L, %d+B' },
              { find = '; after #%d+' },
              { find = '; before #%d+' },
            },
          },
          view = 'mini',
        },

        -- Suppress notifications containing the following patterns
        filter_pattern "in function '__index'", -- some md error when moving files
        filter_pattern 'method textDocument/documentHighlight is not supported by any of the servers registered for the current buffer ', -- likely a LSP thing, encoundered on JSON file
      },
      presets = {
        bottom_search = true,
        command_palette = false,
        long_message_to_split = true,
        lsp_doc_border = true, -- add a border to hover docs and signature help
      },
    },
    -- stylua: ignore
    keys = {
      -- noh is setup in snacks.lua
      { "<leader>noH", function() require("noice").cmd("history") end, desc = "Noice History" },
      { "<leader>nof", function() require("noice").cmd("pick") end, desc = "Noice Picker (Telescope/FzfLua)" },
      { "<leader>cl", function() require("noice").cmd("dismiss") end, desc = "Noice: [cl]ear all notiffications (dismiss)" },
      { "S-Enter>", function() require("noice").redirect(vim.fn.getcmdline()) end, mode = "c", desc = "Redirect Cmdline" },
    },
    config = function(_, opts)
      -- LazyVim thing for initialization
      if vim.o.filetype == 'lazy' then
        vim.cmd [[messages clear]]
      end
      require('noice').setup(opts)
    end,
  },
}
