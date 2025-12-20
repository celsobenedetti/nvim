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
    config = function()
      require('markdown-plus').setup({
        keymaps = {
          enabled = false, -- Disable all default keymaps
        },
      })

      --- Text formatting
      -- Normal mode
      vim.keymap.set('n', '<C-b>', '<Plug>(MarkdownPlusBold)')
      vim.keymap.set('n', '<C-i>', '<Plug>(MarkdownPlusItalic)')
      -- vim.keymap.set('n', '<C-s>', '<Plug>(MarkdownPlusStrikethrough)') -- conflicts with save
      vim.keymap.set('n', '<C-k>', '<Plug>(MarkdownPlusCode)')
      vim.keymap.set('n', '<C-x>', '<Plug>(MarkdownPlusClearFormatting)')

      -- Visual mode
      vim.keymap.set('x', '<C-b>', '<Plug>(MarkdownPlusBold)')
      vim.keymap.set('x', '<C-i>', '<Plug>(MarkdownPlusItalic)')
      vim.keymap.set('x', '<C-s>', '<Plug>(MarkdownPlusStrikethrough)')
      vim.keymap.set('x', '<C-k>', '<Plug>(MarkdownPlusCode)')
      vim.keymap.set('x', '<leader>mw', '<Plug>(MarkdownPlusCodeBlock)')
      vim.keymap.set('x', '<C-x>', '<Plug>(MarkdownPlusClearFormatting)')

      --- Headers & TOC
      vim.keymap.set('n', 'gn', '<Plug>(MarkdownPlusNextHeader)')
      vim.keymap.set('n', 'gp', '<Plug>(MarkdownPlusPrevHeader)')
      vim.keymap.set('n', '<leader>h+', '<Plug>(MarkdownPlusPromoteHeader)')
      vim.keymap.set('n', '<leader>h-', '<Plug>(MarkdownPlusDemoteHeader)')
      vim.keymap.set('n', '<leader>ht', '<Plug>(MarkdownPlusGenerateTOC)')
      vim.keymap.set('n', '<leader>hu', '<Plug>(MarkdownPlusUpdateTOC)')
      vim.keymap.set('n', '<leader>hT', '<Plug>(MarkdownPlusOpenTocWindow)')
      vim.keymap.set('n', '<CR>', '<Plug>(MarkdownPlusFollowLink)') -- Follow TOC link

      --- Header levels (H1-H6)
      for i = 1, 6 do
        vim.keymap.set('n', '<leader>' .. i, '<Plug>(MarkdownPlusHeader' .. i .. ')')
      end

      --- Links
      vim.keymap.set('n', '<leader>li', '<Plug>(MarkdownPlusInsertLink)')
      vim.keymap.set('v', '<leader>li', '<Plug>(MarkdownPlusSelectionToLink)')
      vim.keymap.set('n', '<leader>le', '<Plug>(MarkdownPlusEditLink)')
      vim.keymap.set('n', '<leader>lr', '<Plug>(MarkdownPlusConvertToReference)')
      vim.keymap.set('n', '<leader>ln', '<Plug>(MarkdownPlusConvertToInline)')
      vim.keymap.set('n', '<leader>la', '<Plug>(MarkdownPlusAutoLinkURL)')

      --- Images
      vim.keymap.set('n', '<leader>mL', '<Plug>(MarkdownPlusInsertImage)')
      vim.keymap.set('v', '<leader>mL', '<Plug>(MarkdownPlusSelectionToImage)')
      vim.keymap.set('n', '<leader>mE', '<Plug>(MarkdownPlusEditImage)')
      vim.keymap.set('n', '<leader>mA', '<Plug>(MarkdownPlusToggleImageLink)')

      --- List  Management
      -- Insert mode
      vim.keymap.set('i', '<C-CR>', '<Plug>(MarkdownPlusListEnter)')
      vim.keymap.set('i', '<A-CR>', '<Plug>(MarkdownPlusListShiftEnter)')
      -- vim.keymap.set('i', '<C-]>', '<Plug>(MarkdownPlusListIndent)') -- conflicts with supermaven
      vim.keymap.set('i', '<C-[>', '<Plug>(MarkdownPlusListOutdent)')
      vim.keymap.set('i', '<C-h>', '<Plug>(MarkdownPlusListBackspace)')
      vim.keymap.set('i', '<C-t>', '<Plug>(MarkdownPlusToggleCheckbox)')

      -- Normal mode
      vim.keymap.set('n', '<leader>lr', '<Plug>(MarkdownPlusRenumberLists)')
      vim.keymap.set('n', '<leader>ld', '<Plug>(MarkdownPlusDebugLists)')
      vim.keymap.set('n', 'o', '<Plug>(MarkdownPlusNewListItemBelow)')
      vim.keymap.set('n', 'O', '<Plug>(MarkdownPlusNewListItemAbove)')
      vim.keymap.set('n', '<leader>mx', '<Plug>(MarkdownPlusToggleCheckbox)')

      -- Visual mode
      vim.keymap.set('x', '<leader>mx', '<Plug>(MarkdownPlusToggleCheckbox)')

      --- Quotes
      -- Normal mode
      vim.keymap.set('n', '<C-q>', '<Plug>(MarkdownPlusToggleQuote)')
      -- Visual mode
      vim.keymap.set('x', '<C-q>', '<Plug>(MarkdownPlusToggleQuote)')

      --- Callouts
      -- Normal mode - Insert callout
      vim.keymap.set('n', '<leader>mc', '<Plug>(MarkdownPlusInsertCallout)')
      -- Visual mode - Wrap selection in callout
      vim.keymap.set('x', '<leader>mc', '<Plug>(MarkdownPlusInsertCallout)')
      -- Toggle callout type (cycle through types)
      vim.keymap.set('n', '<leader>mC', '<Plug>(MarkdownPlusToggleCalloutType)')
      -- Convert blockquote to callout
      vim.keymap.set('n', '<leader>m>c', '<Plug>(MarkdownPlusConvertToCallout)')
      -- Convert callout to blockquote
      vim.keymap.set('n', '<leader>m>b', '<Plug>(MarkdownPlusConvertToBlockquote)')

      --- Footnotes
      vim.keymap.set('n', '<leader>fi', '<Plug>(MarkdownPlusFootnoteInsert)')
      vim.keymap.set('n', '<leader>fe', '<Plug>(MarkdownPlusFootnoteEdit)')
      vim.keymap.set('n', '<leader>fd', '<Plug>(MarkdownPlusFootnoteDelete)')
      vim.keymap.set('n', '<leader>fg', '<Plug>(MarkdownPlusFootnoteGotoDefinition)')
      vim.keymap.set('n', '<leader>fr', '<Plug>(MarkdownPlusFootnoteGotoReference)')
      vim.keymap.set('n', '<leader>fn', '<Plug>(MarkdownPlusFootnoteNext)')
      vim.keymap.set('n', '<leader>fp', '<Plug>(MarkdownPlusFootnotePrev)')
      vim.keymap.set('n', '<leader>fl', '<Plug>(MarkdownPlusFootnoteList)')

      --- Tables
      -- Table operations with different prefix
      vim.keymap.set('n', '<leader>Tc', '<Plug>(markdown-plus-table-create)')
      vim.keymap.set('n', '<leader>Tf', '<Plug>(markdown-plus-table-format)')
      vim.keymap.set('n', '<leader>Tn', '<Plug>(markdown-plus-table-normalize)')

      -- Row operations
      vim.keymap.set('n', '<leader>Tir', '<Plug>(markdown-plus-table-insert-row-below)')
      vim.keymap.set('n', '<leader>TiR', '<Plug>(markdown-plus-table-insert-row-above)')
      vim.keymap.set('n', '<leader>Tdr', '<Plug>(markdown-plus-table-delete-row)')
      vim.keymap.set('n', '<leader>Tyr', '<Plug>(markdown-plus-table-duplicate-row)')

      -- Column operations
      vim.keymap.set('n', '<leader>Tic', '<Plug>(markdown-plus-table-insert-column-right)')
      vim.keymap.set('n', '<leader>TiC', '<Plug>(markdown-plus-table-insert-column-left)')
      vim.keymap.set('n', '<leader>Tdc', '<Plug>(markdown-plus-table-delete-column)')
      vim.keymap.set('n', '<leader>Tyc', '<Plug>(markdown-plus-table-duplicate-column)')
    end,
  },
}
