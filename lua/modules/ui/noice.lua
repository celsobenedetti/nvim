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
        filter 'Debug Failure. False expression', -- BUG: some TS LSP issue 2025-04-02
        filter 'to exit Nvim', --  anoying system message "press :qa to exit" bla bla
        filter 'Attempt to delete a buffer that is in use', --  showing up when closing capture note in orgmode
        filter 'Error detected while processing User Autocommands for "VeryLazy":', -- showing up on notebook
        filter "bad argument #1 to 'pairs'", -- some cmp bug 2025-05-19
        filter "[orgmode] No headline found with title'", -- annoying for my obsidian + orgmode setup
        filter "Can't find file", -- suppress failed "gf" messages

        -- avante jank
        -- filter 'Error detected while processing', -- some autocmd
        -- filter 'Error executing lua callback: deserialize error: missing field',
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
