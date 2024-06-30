---@diagnostic disable: param-type-mismatch
local spec = {

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
      map('n', '<leader>md', ':RenderMarkdownToggle<CR>', { desc = 'Toggle markdown.nvim' })

      require('render-markdown').setup {
        headings = { '󰲡 ', '󰲣 ', '󰲥 ', '󰲧 ', '󰲩 ', '󰲫 ' },
        -- Character to use for the bullet points in lists
        bullets = { '◆', '', '󱨉', '' },
        callout = {
          note = '󰋽 Note',
          tip = '󰌶 Tip',
          important = '󰅾 Important',
          warning = '󰀪 Warning',
          caution = '󰳦 Caution',
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
            backgrounds = { '@markup.heading', '@comment.warning', '@diff.delta', '@diff.minus' },
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
          code = 'ColorColumn',
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

-- vim.api.nvim_create_autocmd({ 'VimEnter' }, {
--   pattern = '*.md',
--   callback = function()
--     vim.api.nvim_feedkeys(Keys 'gg/#<CR>', 'n', true)
--     vim.api.nvim_feedkeys(Keys ':nohlsearch<CR>', 'n', true)
--     require('c.functions').set_colorscheme(vim.g.pretty_colorscheme)
--     require('twilight').enable()
--   end,
--   group = vim.api.nvim_create_augroup('MarkdownGroup', { clear = true }),
--   desc = 'Run on Markdown file when first entering Neovim',
-- })

vim.api.nvim_create_autocmd({ 'VimEnter' }, {
  pattern = 'new_note',
  callback = function()
    require('c.functions').set_colorscheme(vim.g.pretty_colorscheme)
    vim.api.nvim_feedkeys(Keys 'ggi<BS><BS><BS>', 'n', true)
  end,
  group = vim.api.nvim_create_augroup('NewNoteGroup', { clear = true }),
  desc = 'Run when entering new_note files',
})

return spec
