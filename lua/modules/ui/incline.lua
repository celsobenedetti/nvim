return {
  {
    'b0o/incline.nvim',
    enabled = vim.g.incline,
    dependencies = { { 'nvim-mini/mini.icons', config = true } },
    config = function()
      local is_notes = require('lib.cwd').matches({ 'notes' })
      if is_notes then
        -- set winbar to render empty line above first line of file
        -- this is done mostly because of obsidian notes, which don't contain a top level H1 by default
        vim.opt.winbar = ' '
      end

      -- local helpers = require('incline.helpers')
      local devicons = require('nvim-web-devicons')
      require('incline').setup({
        window = {
          padding = 0,
          margin = { horizontal = 0 },
          placement = {
            horizontal = is_notes and 'left' or 'right',
            vertical = 'top',
          },
          overlap = {
            winbar = true,
          },
        },
        render = function(props)
          local filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(props.buf), ':t')
          if filename == '' then
            filename = '[No Name]'
          end
          local ft_icon, ft_color = devicons.get_icon_color(filename)
          local modified = vim.bo[props.buf].modified
          return {
            ft_icon
                and {
                  ' ',
                  ft_icon,
                  ' ',
                  guifg = ft_color,
                  -- guibg = helpers.contrast_color(ft_color),
                }
              or '',
            { filename, gui = modified and 'bold,italic' or 'bold' },
            ' ',
            -- guibg = '#44406e',
          }
        end,
      })
    end,
    event = 'VeryLazy',
  },
}
