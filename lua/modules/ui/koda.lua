return {
  {
    'oskarnurm/koda.nvim',
    config = function()
      require('koda').setup(
        ---@type koda.Config
        {
          transparent = true,
          styles = {
            functions = { bold = true },
            keywords = {},
            comments = {},
            strings = {},
            constants = {}, -- includes numbers, booleans
          },

          colors = {
            bg = '#101010', -- editor background
            fg = '#b0b0b0', -- primary text color
            dim = '#50585d', -- line numbers, inlay hints
            line = '#272727', -- line highlights
            keyword = '#777777', -- language syntax
            comment = '#50585d', -- code comments
            border = '#ffffff', -- floating window borders
            emphasis = '#ffffff', -- bold text and prominent UI elements
            func = '#ffffff', -- function names and headings
            string = '#ffffff', -- string literals
            const = '#d9ba73', -- numbers, booleans, and constants
            highlight = '#b0b0b0', -- search results and selection base
            info = '#8ebeec', -- diagnostic hints and informative icons
            success = '#86cd82', -- added git lines and positive diagnostics
            warning = '#d9ba73', -- modified git lines and warning diagnostics
            danger = '#ff7676', -- removed git lines and error diagnostics
          },
        }
      )

      vim.schedule(function()
        vim.api.nvim_set_hl(0, 'String', { fg = '#86cd82' })
      end)
    end,
  },
}
