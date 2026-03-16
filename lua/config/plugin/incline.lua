return {
  config = function()
    -- set winbar to render empty line above first line of file
    -- this is done mostly because of obsidian notes, which don't contain a top level H1 by default
    vim.opt.winbar = ' '
    local devicons = require('nvim-web-devicons')
    require('incline').setup({
      window = {
        padding = 0,
        margin = { horizontal = 0 },
        placement = {
          -- horizontal = is_notes and 'center' or 'right',
          horizontal = 'center',
          vertical = 'top',
        },
        overlap = {
          winbar = true,
        },
      },
      ignore = {
        buftypes = {
          -- '',
          'acwrite',
          -- -- 'help',
          'nofile',
          'nowrite',
          'quickfix',
          'prompt',
        },
        filetypes = {},
        floating_wins = true,
        unlisted_buffers = false,
        wintypes = 'special',
      },
      render = function(props)
        local filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(props.buf), ':t')
        if filename == '' then
          filename = '[No Name]'
        end

        local ft_icon, ft_color = devicons.get_icon_color(filename)
        local modified = vim.bo[props.buf].modified

        if filename == '0.org' then
          ft_icon = ''
          filename = 'note'

          if vim.b.capture_buffer ~= nil then
            local l = vim.api.nvim_buf_get_lines(vim.b.capture_buffer, 0, 1, false)[1]
            if l then
              if l:match('TODO') or l:match('NEXT') or l:match('PROG') then
                ft_icon = ''
                filename = 'action'
              end

              if l:match('UPCOMING') then
                ft_icon = ''
                filename = 'event'
              end
            end
          end
        end

        if filename == 'bash' then
          ft_icon = ''
          filename = 'term'
        end

        if filename:find('.md') then
          filename = filename:gsub('.md', '')
        end

        local icon = ft_icon and { ' ', ft_icon, ' ', guifg = ft_color } or ''
        local file = { filename, gui = modified and 'bold,italic' or 'bold' }

        return { icon, file, ' ' }
      end,
    })
  end,
}
