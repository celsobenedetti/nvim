return {
  {
    'nanozuki/tabby.nvim',
    event = 'TabNew',
    keys = {
      {
        '<leader><tab>r',
        '<cmd>RenameTab<CR>',
        desc = 'tab: rename tab',
      },
    },
    config = function()
      local theme = {
        fill = 'TabLineFill',
        head = 'TabLine',
        current_tab = 'TabLineSel',
        tab = 'TabLine',
        win = 'TabLine',
        tail = 'TabLine',
      }

      require('tabby').setup({
        line = function(line)
          return {
            line.tabs().foreach(function(tab)
              local icon = tab.number() == 1 and ' ' or ''

              tab.wins().foreach(function(win)
                local bu = vim.bo[win.buf().id]
                local ft = bu.filetype or ''
                if ft == 'octo' or ft == 'octo_panel' then
                  icon = ' '
                end
              end)

              local hl = tab.is_current() and theme.current_tab or theme.tab
              return {
                icon,
                tab.name(),
                line.sep(' ', hl, theme.fill),
                hl = hl,
                margin = ' ',
              }
            end),
            line.spacer(),
            hl = theme.fill,
          }
        end,
      })
    end,
  },
}
