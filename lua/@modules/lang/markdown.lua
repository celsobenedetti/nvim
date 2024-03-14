-- TODO: extract markdown module for all markdown config
return {
  {
    'zk-org/zk-nvim',
    ft = 'markdown',
    keys = {
      { '<leader>zn', ':ZkNewFromTitleSelection<CR>', mode = 'v' },
      { '<leader>zn', ':ZkNewFromTitleSelection<CR>', mode = 'v' },
      { '<leader>zz', ':ZkNotes<CR>' },
      { '<leader>zb', ':ZkBacklinks<CR>' },
      { '<leader>zt', ':ZkTags<CR>' },
      { '<leader>zm', ':ZkMatch<CR>', mode = 'v' },
      { '<leader>zl', ':ZkLinks<CR>' },
      { '<leader>zL', ':ZkInsertLink<CR>' },
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

      vim.keymap.set('v', '<c-k>', require('functions.markdown').wrap.link, { desc = 'Wrap current selection in markdown link' })
      vim.keymap.set('v', '<leader>k', require('functions.markdown').wrap.link, { desc = 'Wrap current selection in markdown link' })
      vim.keymap.set('v', '<leader>i', require('functions.markdown').wrap.italic, { desc = 'Wrap current selection in italic' })
      vim.keymap.set('v', '<c-b>', require('functions.markdown').wrap.bold, { desc = 'Wrap current selection in bold' })
      vim.keymap.set('v', '<leader>b', require('functions.markdown').wrap.bold, { desc = 'Wrap current selection in bold' })
      vim.keymap.set('v', '<c-t>', require('functions.markdown').wrap.strikethrough, { desc = 'Strikethrough current selection in bold' })
      vim.keymap.set('v', '<leader>t', require('functions.markdown').wrap.strikethrough, { desc = 'Strikethrough current selection in bold' })
      vim.keymap.set('v', '<leader>`', require('functions.markdown').wrap.code, { desc = 'Wrap current selection in code' })

      vim.keymap.set('i', '<c-b>', function()
        vim.api.nvim_feedkeys(Keys '****<Esc>hha', 'n', true)
      end, { desc = 'Add bold tags for insert mode in bold' })

      vim.keymap.set('i', '<c-t>', function()
        vim.api.nvim_feedkeys(Keys '~~~~<Esc>hha', 'n', true)
      end, { desc = 'Add Strikeghrough italic tags for insert mode in bold' })
    end,
  },

  -- {
  --   'lukas-reineke/headlines.nvim',
  --   config = function()
  --     require('headlines').setup {
  --       markdown = {
  --         headline_highlights = { 'DevIconEditorConfig' },
  --         codeblock_highlight = 'None',
  --         dash_highlight = 'None',
  --         dash_string = '',
  --
  --         quote_highlight = 'None',
  --         quote_string = '>',
  --         fat_headlines = true,
  --         fat_headline_upper_string = '',
  --         fat_headline_lower_string = '━',
  --       },
  --     }
  --   end,
  -- },

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
      ---@diagnostic disable-next-line: param-type-mismatch
      return not string.match(path, 'templates')
    end,
    opts = function(_, opts)
      opts.new_notes_location = 'notes_subdir'
      opts.workspaces = {
        {
          name = 'notes',
          path = '~/Documents/notes',
          overrides = {
            notes_subdir = '0-inbox',
          },
        },
      }
      opts.ui = {
        checkboxes = {
          [' '] = { char = '󰄱', hl_group = 'ObsidianTodo' },
          ['>'] = { char = '', hl_group = 'ObsidianRightArrow' },
          ['~'] = { char = 'x', hl_group = 'ObsidianTilde' },
          ['x'] = { char = '✔', hl_group = 'ObsidianDone' },
        },
      }
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
}
