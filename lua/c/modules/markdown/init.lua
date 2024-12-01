vim.api.nvim_set_hl(0, 'markdownLinkText', { fg = '#000000' }) ---
-- https://github.com/OXY2DEV/markview.nvim
---
---@diagnostic disable: param-type-mismatch
return {
  {
    'celsobenedetti/zk-nvim',
    ft = 'markdown',
    keys = {
      { '<leader>n', ':ZkNewFromTitleSelection<CR>', mode = 'v' },
      { '<leader>zn', ':ZkNewFromTitleSelection<CR>', mode = 'v' },
      { '<leader>zz', ':ZkNotes<CR>' },
      { '<leader>zb', ':ZkBacklinks<CR>' },
      { '<leader>zt', ':ZkTags<CR>' },
      { '<leader>zm', ':ZkMatch<CR>', mode = 'v' },
      { '<leader>zl', ':ZkInsertLink<CR>' },
      { '<leader>zL', ':ZkLinks<CR>' },
      { '<leader>ch', ':norm @c<CR>', mode = 'v' },
      {
        '<leader>P',
        function()
          vim.api.nvim_feedkeys(Keys 'vip', 'n', true)
          vim.api.nvim_feedkeys(Keys '!prettier --parser=markdown<CR>', 'n', true)
        end,
        mode = 'n',
      },
      {
        '<leader>P',
        function()
          vim.api.nvim_feedkeys(Keys '!prettier --parser=markdown<CR>', 'n', true)
        end,
        mode = 'v',
      },
    },
    dependencies = {
      {
        'williamboman/mason.nvim',
        opts = function(_, opts)
          if type(opts.ensure_installed) == 'table' then
            vim.list_extend(opts.ensure_installed, { 'zk' })
          end
        end,
      },
    },

    config = function()
      require('zk').setup {
        picker = 'telescope',
      }

      map('n', '<leader>remove', function()
        vim.api.nvim_feedkeys(Keys ':!rm %<CR>', 'n', true)
        vim.api.nvim_feedkeys(Keys ':bdelete<cr>', 'n', true)
      end, { desc = 'rm buffer file' })

      vim.keymap.set('i', '<c-b>', function()
        vim.api.nvim_feedkeys(Keys '****<Esc>hha', 'n', true)
      end, { desc = 'Add bold tags for insert mode in bold' })

      vim.keymap.set('i', '<c-t>', function()
        vim.api.nvim_feedkeys(Keys '~~~~<Esc>hha', 'n', true)
      end, { desc = 'Add Strikeghrough italic tags for insert mode in bold' })
    end,
  },

  {
    'epwalsh/obsidian.nvim',
    -- commit = "06154ec6f2964632d53c8fea9f0c175f31357192",
    version = '*', -- recommended, use latest release instead of latest commit
    vscode = false,
    lazy = true,
    ft = 'markdown',
    keys = {
      { '<leader>zk', ':ObsidianSearch<CR>' },
      { '<leader>oo', ':ObsidianOpen<CR>' },
      { '<leader>ob', ':ObsidianBacklinks<CR>' },
      { '<leader>ol', ':ObsidianLinks<CR>' },
      { '<leader>ot', ':ObsidianTags<CR>' },
      { '<leader>ch', ':norm @c<CR>', mode = 'v' },
    },
    cond = function()
      local path = vim.fn.expand '%:p:h'
      local is_notes = string.match(path, 'notes')
      local is_templates = string.match(path, 'templates')
      return is_notes and not is_templates
    end,
    opts = function(_, opts)
      opts.new_notes_location = 'notes_subdir'
      opts.workspaces = {
        {
          name = 'notes',
          path = '~/notes',
          overrides = {
            notes_subdir = '0-inbox',
          },
        },
      }
      opts.ui = {
        enable = false,
        checkboxes = {
          [' '] = { char = '󰄱', hl_group = 'ObsidianTodo' },
          ['>'] = { char = '', hl_group = 'ObsidianRightArrow' },
          ['~'] = { char = 'x', hl_group = 'ObsidianTilde' },
          ['x'] = { char = '✔', hl_group = 'ObsidianDone' },
        },
      }
      opts.note_id_func = function(title)
        return title
      end
      opts.note_frontmatter_func = function(note)
        local frontmatter = {
          id = note.id,
          aliases = note.aliases,
          title = note.title,
          date = note.date,
          tags = note.tags,
        }
        if note.metadata ~= nil and not vim.tbl_isempty(note.metadata) then
          for k, v in pairs(note.metadata) do
            frontmatter[k] = v
          end
        end
        return frontmatter
      end
    end,
    dependencies = {
      'nvim-lua/plenary.nvim',
    },
  },

  {
    'MeanderingProgrammer/markdown.nvim',
    ft = 'markdown',
    dependencies = {
      'nvim-treesitter/nvim-treesitter', -- Mandatory
      'nvim-tree/nvim-web-devicons', -- Optional but recommended
    },
    config = function()
      map('n', '<leader>md', ':RenderMarkdown toggle<CR>', { desc = 'Toggle markdown.nvim' })

      require('render-markdown').setup {
        headings = { '󰲡 ', '󰲣 ', '󰲥 ', '󰲧 ', '󰲩 ', '󰲫 ' },
        -- Character to use for the bullet points in lists
        -- { '', '◆  ','',  '', '' }
        bullet = {
          enabled = true,
          highlight = 'RenderMarkdownBullet',
          icons = { '', '', '', '' },
        },
        callout = {
          note = { raw = '[!NOTE]', rendered = '󰋽 Note', highlight = 'DiagnosticInfo' },
          tip = { raw = '[!TIP]', rendered = '󰌶 Tip', highlight = 'DiagnosticOk' },
          idea = { raw = '[!idea]', rendered = '󰌶 Idea', highlight = 'DiagnosticOk' },
          ideas = { raw = '[!ideas]', rendered = '󰌶 Ideas', highlight = 'DiagnosticOk' },
          important = { raw = '[!IMPORTANT]', rendered = '󰅾 Important', highlight = 'DiagnosticHint' },
          warning = { raw = '[!WARNING]', rendered = '󰀪 Warning', highlight = 'DiagnosticWarn' },
          caution = { raw = '[!CAUTION]', rendered = '󰳦 Caution', highlight = 'DiagnosticError' },
          -- Obsidian: https://help.a.md/Editing+and+formatting/Callouts
          abstract = { raw = '[!ABSTRACT]', rendered = '󰨸 Abstract', highlight = 'DiagnosticInfo' },
          todo = { raw = '[!TODO]', rendered = '󰗡 Todo', highlight = 'DiagnosticInfo' },
          success = { raw = '[!SUCCESS]', rendered = '󰄬 Success', highlight = 'DiagnosticOk' },
          question = { raw = '[!QUESTION]', rendered = '󰘥 Question', highlight = 'DiagnosticWarn' },
          failure = { raw = '[!FAILURE]', rendered = '󰅖 Failure', highlight = 'DiagnosticError' },
          danger = { raw = '[!DANGER]', rendered = '󱐌 Danger', highlight = 'DiagnosticError' },
          bug = { raw = '[!BUG]', rendered = '󰨰 Bug', highlight = 'DiagnosticError' },
          bugs = { raw = '[!bugs]', rendered = '󰨰 Bugs', highlight = 'DiagnosticError' },
          example = { raw = '[!EXAMPLE]', rendered = '󰉹 Example', highlight = 'DiagnosticHint' },
          quote = { raw = '[!QUOTE]', rendered = '󱆨 Quote', highlight = '@markup.quote' },
          hot = { raw = '[!HOT]', rendered = '󰈸 Hot', highlight = 'DiagnosticWarn' },
        },
        markdown_query = [[
        (atx_heading [
            (atx_h1_marker)
            (atx_h2_marker)
            (atx_h3_marker)
            (atx_h4_marker)
            (atx_h5_marker)
            (atx_h6_marker)
        ] @heading)

        (thematic_break) @dash

        (fenced_code_block) @code

        [
            (list_marker_plus)
            (list_marker_minus)
            (list_marker_star)
        ] @list_marker

        (task_list_marker_unchecked) @checkbox_unchecked
        (task_list_marker_checked) @checkbox_checked

        (block_quote (block_quote_marker) @quote_marker)
        (block_quote (block_continuation) @quote_marker)
        (block_quote (paragraph (block_continuation) @quote_marker))
        (block_quote (paragraph (inline (block_continuation) @quote_marker)))

        (pipe_table) @table
        (pipe_table_header) @table_head
        (pipe_table_delimiter_row) @table_delim
        (pipe_table_row) @table_row
    ]],
        -- Capture groups that get pulled from inline markdown
        inline_query = [[
        (code_span) @code

        (shortcut_link) @callout

    ]],

        highlights = {
          heading = {
            -- Background of heading line
            backgrounds = { 'CursorLine', '@comment.warning', '@diff.minus', '@diff.plus' },
            -- Foreground of heading character only
            foregrounds = {
              'markdownH1',
              'markdownH2',
              'markdownH3',
              'markdownH4',
              'markdownH5',
              'markdownH6',
            },
          },
          -- Horizontal break
          dash = 'LineNr',
          -- Code blocks
          code = 'CursorLine',
          -- Bullet points in list
          bullet = 'Normal',
          checkbox = {
            -- Unchecked checkboxes
            unchecked = '@markup.list.unchecked',
            -- Checked checkboxes
            checked = '@markup.heading',
          },
          table = {
            -- Header of a markdown table
            head = '@markup.heading',
            -- Non header rows in a markdown table
            row = 'Normal',
          },
          -- LaTeX blocks
          latex = '@markup.math',
          -- Quote character in a block quote
          quote = '@markup.quote',
          -- Highlights to use for different callouts
          callout = {
            note = 'DiagnosticInfo',
            tip = 'DiagnosticOk',
            important = 'DiagnosticHint',
            warning = 'DiagnosticWarn',
            caution = 'DiagnosticError',
          },
        },
      }
    end,
  },
}
