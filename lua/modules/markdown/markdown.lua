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

  -- QoL text editing utilities
  {
    'yousefhadder/markdown-plus.nvim',
    ft = { 'markdown', 'org' },
    config = function()
      require('markdown-plus').setup({
        keymaps = {
          enabled = false, -- Disable all default keymaps
        },
      })
    end,
  },
  -- {
  --   'iwe-org/iwe.nvim',
  --   dependencies = {
  --     'folke/snacks.nvim',
  --   },
  --   config = function()
  --     require('iwe').setup({
  --       lsp = {
  --         cmd = { 'iwes' },
  --         auto_format_on_save = false,
  --         enable_inlay_hints = true,
  --         debounce_text_changes = 500,
  --       },
  --       mappings = {
  --         enable_markdown_mappings = false, -- Core markdown editing keybindings
  --         enable_picker_keybindings = true, -- Set to true to enable gf, gs, ga, g/, gb, gR, go
  --         enable_lsp_keybindings = false, -- Set to true to enable IWE-specific LSP keybindings
  --         enable_preview_keybindings = false, -- Set to true to enable preview keybindings
  --         leader = '<leader>',
  --         localleader = '<localleader>',
  --       },
  --       picker = {
  --         backend = 'snacks',
  --         fallback_notify = true,
  --       },
  --       telescope = {
  --         enabled = false,
  --         setup_config = true,
  --         load_extensions = { 'ui-select', 'emoji' },
  --       },
  --     })
  --   end,
  -- },
}
