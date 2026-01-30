return {
  {
    'nanozuki/tabby.nvim',
    event = 'TabNew',
    keys = {
      {
        '<leader><tab>r',
        vim.g.fn.rename_tab,
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
              local hl = tab.is_current() and theme.current_tab or theme.tab
              return {
                -- line.sep(vim.g.icons.separator.right, hl, theme.fill),
                -- tab.is_current() and '' or '󰆣',
                tab.number() == 1 and ' ' or '',
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
