return {
  {
    'nvim-orgmode/orgmode',
    -- PERF: is this too slow for every day usage? ?
    event = 'VeryLazy',
    ft = { 'org' },
    keys = {
      -- {
      --   '<leader>oaa',
      --   ':Org agenda a<CR>',
      --   desc = 'Org agenda week',
      -- },
      -- {
      --   '<leader>oR',
      --   function()
      --     require('orgmode').agenda:redo()
      --   end,
      --   desc = 'Reindex agenda',
      -- },
      {
        '<leader>ops',
        function()
          vim.notify(_G.orgmode.statusline())
        end,
        desc = 'Org print status: current active task',
      },
    },

    config = function()
      -- Setup orgmode
      require('orgmode').setup {
        org_agenda_files = { '~/notes/orgfiles/**/*' },
        calendar_week_start_day = 0,
        -- org_agenda_start_on_weekday = 0
        -- org_agenda_start_day = '+6d',

        org_default_notes_file = '~/notes/orgfiles/refile.org',

        org_capture_templates = {
          w = {
            description = 'Work task',
            template = '* TODO %? :work:',
            target = '~/notes/orgfiles/work.org',
            headline = 'todo',
          },

          l = {
            description = 'Life task',
            template = '* TODO %? :life:',
            target = '~/notes/orgfiles/life.org',
            headline = 'todo',
          },

          c = {
            description = 'quick capture',
            template = '* %?',
            target = '~/notes/orgfiles/refile.org',
            -- headline = 'todo',
          },
        },

        mappings = {
          org = {
            -- TODO: This is broken, want to remvoe keymap
            -- BUG: This is broken, want to remvoe keymap
            org_set_tags_command = false,
            -- org_agenda_set_tags = '<nop>',
            org_toggle_checkbox = '<leader><C-Space>',
            org_insert_todo_heading_respect_content = '<leader>tod',
          },
        },

        org_todo_keywords = { 'TODO', 'DONE' },
      }

      -- NOTE: If you are using nvim-treesitter with ~ensure_installed = "all"~ option
      -- add ~org~ to ignore_install
      -- require('nvim-treesitter.configs').setup {
      --   ensure_installed = 'all',
      --   ignore_install = { 'org' },
      -- }
    end,
  },

  {
    'nvim-orgmode/telescope-orgmode.nvim',
    -- event = 'VeryLazy',
    dependencies = {
      'nvim-orgmode/orgmode',
      'nvim-telescope/telescope.nvim',
    },
    config = function()
      require('telescope').load_extension 'orgmode'
    end,

    keys = {
      {
        '<leader>tor',
        function()
          require('telescope').extensions.orgmode.refile_heading()
        end,
        desc = 'Telescope Orgmode refile_heading',
      },

      {
        '<leader>re',
        function()
          require('telescope').extensions.orgmode.refile_heading()
        end,
        desc = 'Telescope Orgmode refile_heading :hot:',
      },
      {
        '<leader>tos',
        function()
          require('telescope').extensions.orgmode.search_headings()
        end,
        desc = 'Telescope Orgmode search_headings',
      },

      {
        '<leader>os',
        function()
          require('telescope').extensions.orgmode.search_headings()
        end,
        desc = 'Telescope Orgmode search_headings',
      },
      {
        '<leader>toi',
        function()
          require('telescope').extensions.orgmode.insert_link()
        end,
        desc = 'Telescope Orgmode insert_link',
      },

      {
        '<leader>ot',
        function()
          require('telescope').extensions.orgmode.search_headings()
        end,
        desc = 'Telescope Orgmode search_headings',
      },
    },
  },
}
