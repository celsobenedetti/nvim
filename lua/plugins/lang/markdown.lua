return {

  {
    'uga-rosa/cmp-dictionary',
    -- TODO: see if newer versions work
    commit = 'd17bc1f87736b6a7f058b2f246e651d34d648b47',
    config = function()
      local dict = require 'cmp_dictionary'
      dict.setup {
        -- The following are default values.
        exact = 2,
        first_case_insensitive = false,
        document = false,
        document_command = 'wn %s -over',
        async = false,
        sqlite = false,
        max_items = -1,
        capacity = 5,
        debug = false,
      }
      -- dict.update()
      dict.switcher {
        spelllang = {
          en = '~/.dotfiles/english.dict',
        },
      }
    end,
    ft = { 'markdown', 'tex', 'latex', 'vimwiki', 'gitcommit' },
    dependencies = {
      {
        'hrsh7th/nvim-cmp',
        opts = function(_, opts)
          local cmp = require 'cmp'
          opts.sources = cmp.config.sources(vim.list_extend(opts.sources or {}, {
            { name = 'dictionary', keyword_length = 2 },
          }))
        end,
      },
    },
  },

  -- zk
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
      { '<leader>zl', ':ObsidianLinks<CR>' },
      { '<leader>ot', ':ObsidianTags<CR>' },
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
