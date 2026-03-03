return {
  'folke/twilight.nvim',
  lazy = true,
  config = function()
    local dimming = {
      inative = true,
    }

    if vim.opt.background:get() == 'light' then
      dimming = {
        alpha = 0.8,
        color = { 'Normal', '#FFFFFF' }, -- can be a hex color, or a named color (see `:help highlight-groups
        inactive = true, -- when true, other windows will be fully dimmed (unless they contain the same buffer)
      }
    end

    require('twilight').setup({
      dimming = dimming,
      -- context = 10, -- amount of lines we will try to show around the current line
      treesitter = true, -- use treesitter when available for the filetype
      -- treesitter is used to automatically expand the visible text,
      -- but you can further control the types of nodes that should always be fully expanded
      expand = { -- for treesitter, we we always try to expand to the top-most ancestor with these types
        'function',
        'method',
        'table',
        'if_statement',
      },
      exclude = {}, -- exclude these filetypes
    })
  end,

  cmd = { 'Twilight', 'TwilightEnable' },
  keys = {
    { '<leader>tw', '<cmd>Twilight<cr>', desc = 'Toggle Twilight', mode = 'n' },
  },
}
