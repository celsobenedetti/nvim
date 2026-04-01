return {
  {
    'MeanderingProgrammer/render-markdown.nvim',
    keys = { { '<leader>md', ':RenderMarkdown toggle<CR>', desc = 'Toggle render markdown' } },
    ft = { 'markdown', 'norg', 'rmd', 'org', 'codecompanion' },
    config = function()
      require('render-markdown').setup({
        link = {
          enabled = true, -- Turn on / off inline link icon rendering.
          render_modes = false, -- Additional modes to render links.
          footnote = { -- How to handle footnote links, start with a '^'.
            enabled = true, -- Turn on / off footnote rendering.
            icon = '󰯔 ', -- Inlined with content.
            superscript = true, -- Replace value with superscript equivalent.
            prefix = '', -- Added before link content.
            suffix = '', -- Added after link content.
          },
          image = '󰥶 ', -- Inlined with 'image' elements.
          email = '󰀓 ', -- Inlined with 'email_autolink' elements.
          hyperlink = '󰌹 ', -- Fallback icon for 'inline_link' and 'uri_autolink' elements.
          highlight = 'RenderMarkdownLink', -- Applies to the inlined icon as a fallback.
          highlight_title = 'RenderMarkdownLinkTitle', -- Applies to the link title.
          wiki = { -- Applies to WikiLink elements.
            icon = '',
            body = function()
              return nil
            end,
            highlight = 'RenderMarkdownWikiLink',
            scope_highlight = nil,
          },
          custom = {
            discord = { pattern = 'discord%.com', icon = '󰙯 ' },
            github = { pattern = 'github%.com', icon = '󰊤 ' },
            gitlab = { pattern = 'gitlab%.com', icon = '󰮠 ' },
            google = { pattern = 'google%.com', icon = '󰊭 ' },
            linkedin = { pattern = 'linkedin%.com', icon = '󰌻 ' },
            neovim = { pattern = 'neovim%.io', icon = ' ' },
            spotify = { pattern = 'open.spotify.com*', icon = ' ' },
            reddit = { pattern = 'reddit%.com', icon = '󰑍 ' },
            slack = { pattern = 'slack%.com', icon = '󰒱 ' },
            stackoverflow = { pattern = 'stackoverflow%.com', icon = '󰓌 ' },
            steam = { pattern = 'steampowered%.com', icon = ' ' },
            wikipedia = { pattern = 'wikipedia%.org', icon = '󰖬 ' },
            youtube = { pattern = 'youtube[^.]*%.com', icon = '󰗃 ' },
          },
        },
      })

      Snacks.toggle({
        name = 'Render Markdown',
        get = require('render-markdown').get,
        set = require('render-markdown').set,
      }):map('<leader>um')
    end,
  },

  -- lazy.nvim
  {
    'antonk52/markdowny.nvim',
    ft = { 'markdown' },
    config = function()
      require('markdowny').setup()
    end,
  },
}
