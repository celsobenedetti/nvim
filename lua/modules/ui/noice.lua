--- @param pattern string
local function filter(pattern)
  return { filter = { find = pattern }, opts = { skip = true } }
end

return {
  {
    'folke/noice.nvim',
    event = 'VeryLazy',
    lazy = C.opt.performance,
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
        -- Suppress notifications containing the following patterns
        filter "in function '__index'", -- some md error when moving files
        filter 'method textDocument/documentHighlight is not supported by any of the servers registered for the current buffer ', -- likely a LSP thing, encoundered on JSON file
        filter 'Error executing lua Keyboard interrupt', -- Looks like a bufferline thing
        filter 'Error executing vim.schedule lua callback', -- Neotest error
        filter 'airbnb', -- BRO PLEASE STOP 😭
        filter 'textDocument/diagnostic failed with message', -- eslint bs

        -- avante jank
        filter 'Error detected while processing', -- some autocmd
        filter 'Error executing lua callback: deserialize error: missing field',

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
      },
      presets = {
        bottom_search = true,
        command_palette = false,
        long_message_to_split = true,
        lsp_doc_border = true, -- add a border to hover docs and signature help
      },
      views = {
        cmdline_popup = {
          position = {
            row = '40%',
            col = '50%',
          },
          size = {
            width = 60,
            height = 'auto',
          },
        },
        popupmenu = {
          relative = 'editor',
          position = {
            row = '52%',
            col = '50%',
          },
          size = {
            width = 60,
            height = 10,
          },
          border = {
            style = 'rounded',
            padding = { 0, 1 },
          },
          win_options = {
            winhighlight = { Normal = 'Normal', FloatBorder = 'DiagnosticInfo' },
          },
        },
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
