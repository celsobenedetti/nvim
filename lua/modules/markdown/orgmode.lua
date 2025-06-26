--- colors & highlight gruops
-- vim.api.nvim_create_autocmd('ColorScheme', {
--   pattern = '*',
--   callback = function()
--     vim.api.nvim_set_hl(0, '@org.keyword.todo', { fg = '#f7a49c' })
--     vim.api.nvim_set_hl(0, '@org.keyword.done', { fg = '#90e8a1' })
--     vim.api.nvim_set_hl(0, '@org.agenda.deadline', { fg = '#f7a49c' })
--     vim.api.nvim_set_hl(0, '@org.agenda.scheduled', { fg = '#d7dae1' })
--     -- vim.api.nvim_set_hl(0, '@org.agenda.scheduled', { fg = '#90e8a1' })
--     vim.api.nvim_set_hl(0, '@org.agenda.scheduled_past', { fg = '#e0ca90' })
--   end,
-- })

local refile_file = '~/notes/inbox/refile.org'
local org_files = {
  refile_file,
  '~/notes/orgfiles/*',
  '~/notes/inbox/phone_refile.org',
  '~/notes/projects/**/*',
  '~/notes/areas/**/*',
}

map('n', '<leader>i', ':e ~/notes/orgfiles/i.org<cr>', { desc = 'Orgmode index' })
map('n', '<leader>ow', ':e ~/notes/orgfiles/week.org<cr>', { desc = 'Orgmode week file' })
map('n', '<leader>ot', ':Org agenda T<cr>', { desc = 'Orgmode agenda today' })
map('n', '<leader>oW', ':e ~/notes/orgfiles/work.org<cr>', { desc = 'Orgmode work file' })
map('n', '<leader>or', ':e ~/notes/inbox/refile.org<cr>', { desc = 'Orgmode refile file' })

return {
  {
    'nvim-orgmode/orgmode',
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
        -- org_agenda_start_on_weekday = 7, -- start on sunday
        org_agenda_custom_commands = {
          T = {
            description = 'today',
            types = { { type = 'agenda', org_agenda_span = 'day' } },
          },
        },
        org_blank_before_new_entry = { heading = true, plain_list_item = false },

        org_default_notes_file = refile_file,

        ui = {
          virt_cookies = {
            enabled = true,
            type = '/',
          },
        },

        org_capture_templates = {
          w = {
            description = 'Work task',
            template = '* TODO %? :work:\n  %U',
            target = '~/notes/orgfiles/work.org',
            headline = 'work backlog',
          },
          l = {
            description = 'Life task',
            template = '* TODO %? :life:\n  %U',
          },

          c = {
            description = 'quick capture',
            template = '* %?\n  %U',
          },
        },

        mappings = {
          org = {
            org_set_tags_command = false,
            org_refile = false,
            -- org_agenda_set_tags = '<nop>',
            org_toggle_checkbox = '<leader><C-Space>',
            org_insert_todo_heading_respect_content = '<leader>tod',
            org_open_at_point = '<leader>oO',
          },
        },

        org_todo_keywords = {
          'TODO',
          -- 'WIP',
          'DONE',
        },
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

  {
    'akinsho/org-bullets.nvim',
    ft = { 'org' },
    config = function()
      require('org-bullets').setup {
        symbols = {
          headlines = {
            { '○', 'MyBulletL2' },
            { '✸', 'MyBulletL3' },
            { '✿', 'MyBulletL4' },
            { '◉', 'MyBulletL1' },
          },
          checkboxes = {
            half = { '', '@org.checkbox.halfchecked' },
            done = { '✓', '@org.keyword.done' },
            todo = { ' ', '@org.keyword.todo' },
          },
        },
      }
    end,
  },
}
