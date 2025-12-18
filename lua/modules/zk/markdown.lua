return {
  { 'masukomi/vim-markdown-folding', ft = { 'markdown' } },

  {
    'MeanderingProgrammer/render-markdown.nvim',
    keys = { { '<leader>md', ':RenderMarkdown toggle<CR>', desc = 'Toggle render markdown' } },
    ft = { 'markdown', 'norg', 'rmd', 'org', 'codecompanion' },
    config = function()
      require('render-markdown').setup({
        link = {
          enabled = true,
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
          custom = {
            discord = { pattern = 'discord%.com', icon = '󰙯 ' },
            github = { pattern = 'github%.com', icon = '󰊤 ' },
            gitlab = { pattern = 'gitlab%.com', icon = '󰮠 ' },
            google = { pattern = 'google%.com', icon = '󰊭 ' },
            linkedin = { pattern = 'linkedin%.com', icon = '󰌻 ' },
            neovim = { pattern = 'neovim%.io', icon = ' ' },
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

  -- QoL text editing utilities
  {
    'yousefhadder/markdown-plus.nvim',
    ft = 'markdown',
  },
}
