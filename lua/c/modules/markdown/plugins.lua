vim.api.nvim_set_hl(0, 'markdownLinkText', { fg = '#000000' }) ---

vim.g.markdown_fenced_languages = {
  'ts=typescript',
}

-- wrap and check for spell in text filetypes
vim.api.nvim_create_autocmd('FileType', {
  group = Augroup 'wrap_spell',
  pattern = { 'gitcommit', 'markdown' },
  callback = function()
    vim.opt_local.wrap = true
    vim.opt_local.spell = true
  end,
})

-- https://github.com/OXY2DEV/markview.nvim
---
---@diagnostic disable: param-type-mismatch
return {
  {
    'OXY2DEV/markview.nvim',
    lazy = false, -- Recommended
    ft = { 'markdown', 'Avante' }, -- If you decide to lazy-load anyway
    dependencies = {
      'nvim-treesitter/nvim-treesitter',
      'nvim-tree/nvim-web-devicons',
    },
    config = function()
      local presets = require 'markview.presets'

      require('markview').setup {
        checkboxes = presets.checkboxes.nerd,
        headings = presets.headings.slanted,
        -- horizontal_rules = presets.horizontal_rules.thin,
        block_quotes = {
          enable = true,

          --- Default configuration for block quotes.
          default = {
            --- Text to use as border for the block
            --- quote.
            --- Can also be a list if you want multiple
            --- border types!
            ---@type string | string[]
            border = '▋',

            --- Highlight group for "border" option. Can also
            --- be a list to create gradients.
            ---@type (string | string[])?
            hl = 'MarkviewBlockQuoteDefault',
          },

          --- Configuration for custom block quotes
          callouts = {
            {
              --- String between "[!" & "]"
              ---@type string
              match_string = 'ABSTRACT',

              --- Primary highlight group. Used by other options
              --- that end with "_hl" when their values are nil.
              ---@type string?
              hl = 'MarkviewBlockQuoteNote',

              --- Text to show in the preview.
              ---@type string
              preview = '󱉫 Abstract',

              --- Highlight group for the preview text.
              ---@type string?
              preview_hl = nil,

              --- When true, adds the ability to add a title
              --- to the block quote.
              ---@type boolean
              title = true,

              --- Icon to show before the title.
              ---@type string?
              icon = '󱉫 ',

              ---@type string | string
              border = '▋',

              ---@type (string | string[])?
              border_hl = nil,
            },
          },
        },
      }
    end,
    keys = { { '<leader>md', ':Markview<CR>', desc = 'Toggle markview' } },
  },

  -- {
  --   'MeanderingProgrammer/markdown.nvim',
  --   ft = { 'markdown', 'Avante' },
  --   dependencies = {
  --     'nvim-treesitter/nvim-treesitter', -- Mandatory
  --     'nvim-tree/nvim-web-devicons', -- Optional but recommended
  --   },
  --   config = function()
  --     map('n', '<leader>md', ':RenderMarkdown toggle<CR>', { desc = 'Toggle markdown.nvim' })
  --     require('render-markdown').setup {
  --       headings = { '󰲡 ', '󰲣 ', '󰲥 ', '󰲧 ', '󰲩 ', '󰲫 ' },
  --       -- Character to use for the bullet points in lists
  --       -- { '', '◆  ','',  '', '' }
  --       bullet = {
  --         enabled = true,
  --         highlight = 'RenderMarkdownBullet',
  --         icons = { '', '', '', '' },
  --       },
  --       callout = {
  --         note = { raw = '[!NOTE]', rendered = '󰋽 Note', highlight = 'DiagnosticInfo' },
  --         tip = { raw = '[!TIP]', rendered = '󰌶 Tip', highlight = 'DiagnosticOk' },
  --         idea = { raw = '[!idea]', rendered = '󰌶 Idea', highlight = 'DiagnosticOk' },
  --         ideas = { raw = '[!ideas]', rendered = '󰌶 Ideas', highlight = 'DiagnosticOk' },
  --         important = { raw = '[!IMPORTANT]', rendered = '󰅾 Important', highlight = 'DiagnosticHint' },
  --         warning = { raw = '[!WARNING]', rendered = '󰀪 Warning', highlight = 'DiagnosticWarn' },
  --         caution = { raw = '[!CAUTION]', rendered = '󰳦 Caution', highlight = 'DiagnosticError' },
  --         -- Obsidian: https://help.a.md/Editing+and+formatting/Callouts
  --         abstract = { raw = '[!ABSTRACT]', rendered = '󰨸 Abstract', highlight = 'DiagnosticInfo' },
  --         todo = { raw = '[!TODO]', rendered = '󰗡 Todo', highlight = 'DiagnosticInfo' },
  --         success = { raw = '[!SUCCESS]', rendered = '󰄬 Success', highlight = 'DiagnosticOk' },
  --         question = { raw = '[!QUESTION]', rendered = '󰘥 Question', highlight = 'DiagnosticWarn' },
  --         failure = { raw = '[!FAILURE]', rendered = '󰅖 Failure', highlight = 'DiagnosticError' },
  --         danger = { raw = '[!DANGER]', rendered = '󱐌 Danger', highlight = 'DiagnosticError' },
  --         bug = { raw = '[!BUG]', rendered = '󰨰 Bug', highlight = 'DiagnosticError' },
  --         bugs = { raw = '[!bugs]', rendered = '󰨰 Bugs', highlight = 'DiagnosticError' },
  --         example = { raw = '[!EXAMPLE]', rendered = '󰉹 Example', highlight = 'DiagnosticHint' },
  --         quote = { raw = '[!QUOTE]', rendered = '󱆨 Quote', highlight = '@markup.quote' },
  --         hot = { raw = '[!HOT]', rendered = '󰈸 Hot', highlight = 'DiagnosticWarn' },
  --       },
  --       markdown_query = [[
  --       (atx_heading [
  --           (atx_h1_marker)
  --           (atx_h2_marker)
  --           (atx_h3_marker)
  --           (atx_h4_marker)
  --           (atx_h5_marker)
  --           (atx_h6_marker)
  --       ] @heading)
  --
  --       (thematic_break) @dash
  --
  --       (fenced_code_block) @code
  --
  --       [
  --           (list_marker_plus)
  --           (list_marker_minus)
  --           (list_marker_star)
  --       ] @list_marker
  --
  --       (task_list_marker_unchecked) @checkbox_unchecked
  --       (task_list_marker_checked) @checkbox_checked
  --
  --       (block_quote (block_quote_marker) @quote_marker)
  --       (block_quote (block_continuation) @quote_marker)
  --       (block_quote (paragraph (block_continuation) @quote_marker))
  --       (block_quote (paragraph (inline (block_continuation) @quote_marker)))
  --
  --       (pipe_table) @table
  --       (pipe_table_header) @table_head
  --       (pipe_table_delimiter_row) @table_delim
  --       (pipe_table_row) @table_row
  --   ]],
  --       -- Capture groups that get pulled from inline markdown
  --       inline_query = [[
  --       (code_span) @code
  --
  --       (shortcut_link) @callout
  --
  --   ]],
  --
  --       highlights = {
  --         heading = {
  --           -- Background of heading line
  --           backgrounds = { 'CursorLine', '@comment.warning', '@diff.minus', '@diff.plus' },
  --           -- Foreground of heading character only
  --           foregrounds = {
  --             'markdownH1',
  --             'markdownH2',
  --             'markdownH3',
  --             'markdownH4',
  --             'markdownH5',
  --             'markdownH6',
  --           },
  --         },
  --         -- Horizontal break
  --         dash = 'LineNr',
  --         -- Code blocks
  --         code = 'CursorLine',
  --         -- Bullet points in list
  --         bullet = 'Normal',
  --         checkbox = {
  --           -- Unchecked checkboxes
  --           unchecked = '@markup.list.unchecked',
  --           -- Checked checkboxes
  --           checked = '@markup.heading',
  --         },
  --         table = {
  --           -- Header of a markdown table
  --           head = '@markup.heading',
  --           -- Non header rows in a markdown table
  --           row = 'Normal',
  --         },
  --         -- LaTeX blocks
  --         latex = '@markup.math',
  --         -- Quote character in a block quote
  --         quote = '@markup.quote',
  --         -- Highlights to use for different callouts
  --         callout = {
  --           note = 'DiagnosticInfo',
  --           tip = 'DiagnosticOk',
  --           important = 'DiagnosticHint',
  --           warning = 'DiagnosticWarn',
  --           caution = 'DiagnosticError',
  --         },
  --       },
  --     }
  --   end,
  -- },
}
