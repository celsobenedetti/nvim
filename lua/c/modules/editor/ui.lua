local spec = {
  {
    'folke/styler.nvim',
    ft = { 'help' },
    config = function()
      require('styler').setup {
        themes = {
          help = { colorscheme = 'catppuccin-mocha' },
        },
      }
    end,
  },

  -- filenamees
  {
    'b0o/incline.nvim',
    opts = function(_, opts)
      opts.window = { margin = { vertical = 0, horizontal = 1 } }
      opts.hide = { cursorline = true }

      opts.render = function(props)
        local filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(props.buf), ':t')
        if vim.bo[props.buf].modified then
          filename = '[+] ' .. filename
        end

        local icon, color = require('nvim-web-devicons').get_icon_color(filename)
        return { { icon, guifg = color }, { ' ' }, { filename } }
      end
    end,
  },
}

local code_files = {
  '*.lua',
  '*.go',
  '*.ts',
  '*.js',
  '*.tsx',
  '*.jsx',
}

local colorscheme_group = vim.api.nvim_create_augroup('ColorschemeGroup', { clear = true })
vim.api.nvim_create_autocmd({ 'BufEnter' }, {
  pattern = code_files,
  group = colorscheme_group,
  desc = 'Run on code files',
  callback = function()
    vim.cmd.colorscheme(vim.g.code_colorscheme)
  end,
})

vim.api.nvim_create_autocmd({ 'BufWinLeave' }, {
  pattern = code_files,
  group = colorscheme_group,
  desc = 'Run when leaving code files',
  callback = function()
    vim.cmd.colorscheme(vim.g.pretty_colorscheme)
  end,
})

return spec
