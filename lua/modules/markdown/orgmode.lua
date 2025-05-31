--- colors & highlight gruops
vim.api.nvim_create_autocmd('ColorScheme', {
  pattern = '*',
  callback = function()
    vim.api.nvim_set_hl(0, '@org.keyword.todo', { fg = '#ffbcb5' })
    vim.api.nvim_set_hl(0, '@org.keyword.done', { fg = '#aaedb7' })
    vim.api.nvim_set_hl(0, '@org.agenda.deadline', { fg = '#ffbcb5' })
    vim.api.nvim_set_hl(0, '@org.agenda.scheduled', { fg = '#d7dae1' })
    -- vim.api.nvim_set_hl(0, '@org.agenda.scheduled', { fg = '#aaedb7' })
    vim.api.nvim_set_hl(0, '@org.agenda.scheduled_past', { fg = '#f4d88c' })
  end,
})

local org_files = {
  '~/notes/orgfiles/**/*',
  '~/notes/inbox/refile.org',
  '~/notes/inbox/phone_refile.org.org',
  '~/notes/projects/**/*',
  '~/notes/areas/**/*',
}

map('n', '<leader>i', ':e ~/notes/orgfiles/i.org<cr>', { desc = 'Orgmode index' })

return {
  {
    'nvim-orgmode/orgmode',
    -- PERF: is this too slow for every day usage? ?
    event = 'VeryLazy',
    ft = { 'org' },
    keys = {
      { '<leader>oim', ':Org indent_mode<CR>', desc = 'Orgmode: toggle indent_mode' },
    },
    config = function()
      -- Setup orgmode
      require('orgmode').setup {
        org_agenda_files = org_files,
        calendar_week_start_day = 0,
        -- org_agenda_start_on_weekday = 0
        -- org_agenda_start_day = '+6d',
        --
        org_agenda_custom_commands = {
          t = {
            description = 'today',
            types = { { type = 'agenda', org_agenda_span = 'day' } },
          },
        },

        org_default_notes_file = '~/notes/inbox/refile.org',

        org_capture_templates = {
          w = {
            description = 'Work task',
            template = '* TODO %? :work:\n  %U',
            target = '~/notes/orgfiles/work.org',
            headline = 'work todo',
          },
          l = {
            description = 'Life task',
            template = '* TODO %? :life:\n  %U',
            target = '~/notes/orgfiles/areas.org',
            headline = 'backlog life',
          },

          c = {
            description = 'quick capture',
            template = '* %?\n  %U',
            -- target = '~/notes/inbox/refile.org',
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

        org_todo_keywords = { 'CANCELLED', 'WAITING', 'TODO', 'DONE' },
      }

      vim.api.nvim_create_autocmd('ColorScheme', {
        pattern = '*',
        callback = function()
          vim.api.nvim_set_hl(0, '@org.agenda.todo', { fg = '#ffbcb5' })
          vim.api.nvim_set_hl(0, '@org.agenda.done', { fg = '#aaedb7' })
        end,
      })

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

  {
    'akinsho/org-bullets.nvim',
    ft = { 'org' },
    config = function()
      require('org-bullets').setup()
    end,
  },
}
