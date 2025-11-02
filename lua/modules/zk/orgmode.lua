local org_files = {
  vim.g.notes.ORG .. '/**/*',
  vim.g.notes.ORG_REFILE,
}

local function e(file)
  return ':e ' .. file .. '<cr>'
end

map('n', '<leader>i', e(vim.g.notes.ORG_INDEX), { desc = 'Orgmode index' })
map('n', '<leader>ow', e(vim.g.notes.ORG_WORK), { desc = 'Orgmode work file' })
map('n', '<leader>or', e(vim.g.notes.ORG_REFILE), { desc = 'Orgmode refile file' })
map('n', '<leader>rr', e(vim.g.notes.ORG_REFILE), { desc = 'Orgmode refile file' })

-- -- set highlights
-- vim.api.nvim_set_hl(0, '@org.headline.level2', { fg = 'gray' })
vim.api.nvim_set_hl(0, '@org.keyword.done', { fg = 'green' })
-- vim.api.nvim_set_hl(0, '@org.keyword.todo', { fg = 'red' })
vim.api.nvim_set_hl(0, '@org.agenda.scheduled', { fg = 'darkgray' })
-- vim.api.nvim_set_hl(0, '@org.agenda.timegrid', { fg = 'gray' })
-- vim.api.nvim_set_hl(0, '@org.agenda.scheduled_past', { fg = 'gray' })

return {
  {
    'nvim-orgmode/orgmode',
    -- event = "VeryLazy",
    ft = { 'org' },
    keys = {
      { '<leader>oim', ':Org indent_mode<CR>', desc = 'Orgmode: toggle indent_mode' },
      {
        '<leader>T',
        function()
          if vim.fn.expand('%'):match '/' then
            vim.cmd ':w'
          end
          vim.cmd ':Org agenda T'
        end,
        desc = 'Org: Today agenda',
      },
      { '<leader>oct', ':Org capture t<CR>', desc = 'Org: Today agenda' },
      { '<leader>ocw', ':Org capture w<CR>', desc = 'Org: Today agenda' },
    },
    config = function()
      -- Setup orgmode
      require('orgmode').setup {
        org_agenda_files = org_files,
        org_default_notes_file = vim.g.notes.ORG_REFILE,

        calendar_week_start_day = 0,
        -- org_agenda_start_on_weekday = 7, -- start on sunday
        org_agenda_custom_commands = {

          T = {
            description = 'today',
            types = {
              {
                type = 'agenda',
                match = '+PRIORITY="A"', --Same as providing a "Match:" for tags view <leader>oa + m, See: https://orgmode.org/manual/Matching-tags-and-properties.html
                org_agenda_span = 'day',
                org_agenda_sorting_strategy = { 'todo-state-down', 'priority-down' }, -- See all options available on org_agenda_sorting_strategy
              },
            },
          },
          n = {
            description = 'next',
            types = {
              {
                type = 'tags_todo', -- Type can be agenda | tags | tags_todo
                match = '-TODO="TODO"', --Same as providing a "Match:" for tags view <leader>oa + m, See: https://orgmode.org/manual/Matching-tags-and-properties.html
                org_agenda_sorting_strategy = { 'todo-state-down', 'priority-down' }, -- See all options available on org_agenda_sorting_strategy
                -- org_agenda_overriding_header = 'High priority todos',
                -- org_agenda_todo_ignore_deadlines = 'far', -- Ignore all deadlines that are too far in future (over org_deadline_warning_days). Possible values: all | near | far | past | future
              },
            },
          },
          w = {
            description = 'Work tasks',
            types = {
              {
                type = 'tags_todo',
                match = 'work',
                org_agenda_sorting_strategy = { 'todo-state-down' }, -- See all options available on org_agenda_sorting_strategy
              },
            },
          },
        },
        org_blank_before_new_entry = { heading = true, plain_list_item = false },

        -- ui = {
        --   virt_cookies = {
        --     enabled = true,
        --     type = '/',
        --   },
        --   -- folds = {
        --   --   colored = false,
        --   -- },
        -- },

        org_capture_templates = {
          w = {
            description = 'Work task',
            template = '* TODO %? :work:\n  %U',
            target = vim.g.notes.ORG_WORK,
            headline = 'work todo',
          },
          p = {
            description = 'purchase',
            template = '* TODO buy: %? :buy:\n  %U',
            target = vim.g.notes.ORG_PURCHASES,
            headline = 'purchases',
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

        -- mappings = {
        --   agenda = {
        --     org_agenda_switch_to = false,
        --     org_agenda_goto = '<CR>',
        --   },
        --   org = {
        --     org_set_tags_command = nil,
        --     -- org_refile = false,
        --     -- org_agenda_set_tags = '<nop>',
        --     org_toggle_checkbox = '<leader><C-Space>',
        --     org_insert_todo_heading_respect_content = '<leader>tod',
        --     org_open_at_point = '<leader>oO',
        --   },
        -- },

        org_todo_keywords = {
          'TODO(t)', -- Tasks that are not started and not planned. They could be the backlogs or the GTD’s someday/maybe. These tasks could be converted to NEXT during a review.
          'CANC(c)', -- Tasks that have I've decided not to do.
          'NEXT(n)', -- Tasks that are not started but planned to do as soon as I can. When there is no actionable PROG (e.g., blocked), I start one of those and convert it to PROG.
          'PROG(p)', -- Tasks that are working in progress (open loops). I work on these tasks before starting another NEXT task to avoid too many open loops at any moment.
          'DONE(d)', -- 😎👍
        },
      }
    end,
  },

  {
    'nvim-orgmode/telescope-orgmode.nvim',
    lazy = true,
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

  -- {
  --   "akinsho/org-bullets.nvim",
  --   ft = { "org" },
  --   config = function()
  --     require("org-bullets").setup({
  --       symbols = {
  --         headlines = {
  --           { "○", "MyBulletL2" },
  --           { "✸", "MyBulletL3" },
  --           { "✿", "MyBulletL4" },
  --           { "◉", "MyBulletL1" },
  --         },
  --         checkboxes = {
  --           half = { "", "@org.checkbox.halfchecked" },
  --           done = { "✓", "@org.keyword.done" },
  --           todo = { " ", "@org.keyword.todo" },
  --         },
  --       },
  --     })
  --   end,
  -- },

  {
    'saghen/blink.cmp',
    opts = function(_, opts)
      opts.sources = opts.sources or {}
      opts.sources.per_filetype = vim.tbl_extend('force', opts.sources.per_filetype or {}, {
        org = { 'orgmode' },
      })
      opts.sources.providers = vim.tbl_extend('force', opts.sources.providers or {}, {
        orgmode = {
          name = 'Orgmode',
          module = 'orgmode.org.autocompletion.blink',
          fallbacks = { 'buffer' },
        },
      })
    end,
  },
}
