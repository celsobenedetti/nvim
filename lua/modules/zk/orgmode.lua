local omarchy_colorscheme = require('lib.colors').omarchy_colorscheme().colorscheme
local highlight = true
local org_files = {
  vim.g.env.notes.ORG .. '/**/*',
}

local function set_highlights()
  vim.api.nvim_set_hl(0, '@org.keyword.done', { fg = 'green' })
  vim.api.nvim_set_hl(0, '@org.keyword.todo', { fg = 'red' })
  vim.api.nvim_set_hl(0, '@org.agenda.scheduled', { fg = 'darkgray' })
end

local function e(file)
  return ':e ' .. file .. '<cr>'
end
map('n', '<leader>ow', e(vim.g.env.notes.ORG_WORK), { desc = 'org: work file' })
map('n', '<leader>rr', e(vim.g.env.notes.ORG_REFILE), { desc = 'org: refile file' })

return {
  {
    'nvim-orgmode/orgmode',
    -- event = "VeryLazy",
    cmd = { 'Org' },
    ft = { 'org', 'markdown' },
    keys = {
      { '<leader>oim', ':Org indent_mode<CR>', desc = 'org:: toggle indent_mode' },
      {
        '<leader>T',
        function()
          require('lib.notes').focus_or_create_notes_tab(function()
            vim.cmd(':Org agenda T')
          end)
        end,
        desc = 'Org: agenda today',
      },
      { '<leader>oct', ':Org capture t<CR>', desc = 'Org: Today agenda' },
      { '<leader>ocw', ':Org capture w<CR>', desc = 'Org: Today agenda' },
    },
    config = function()
      -- Setup orgmode
      require('orgmode').setup({
        org_agenda_files = org_files,
        org_agenda_sorting_strategy = { 'todo-state-up' },
        org_default_notes_file = vim.g.env.notes.ORG_REFILE,
        org_priority_highest = 'A',
        org_priority_default = 'C',
        org_priority_lowest = 'C',
        org_log_into_drawer = 'LOGBOOK',
        org_startup_indented = true,
        org_adapt_indentation = false,
        org_id_link_to_org_use_id = true,
        calendar_week_start_day = 0,
        -- org_agenda_start_on_weekday = 7, -- start on sunday
        --
        org_agenda_custom_commands = {

          T = {
            description = 'today',
            types = {
              {
                type = 'agenda',
                -- match = '+PRIORITY="A"', --Same as providing a "Match:" for tags view <leader>oa + m, See: https://orgmode.org/manual/Matching-tags-and-properties.html
                org_agenda_span = 'day',
                org_agenda_sorting_strategy = {
                  'time-up',
                  'todo-state-down',
                  'priority-down',
                }, -- See all options available on org_agenda_sorting_strategy
              },
            },
          },
          n = {
            description = 'next',
            types = {
              {
                type = 'tags_todo', -- Type can be agenda | tags | tags_todo
                match = '-TODO="TODO"', --Same as providing a "Match:" for tags view <leader>oa + m, See: https://orgmode.org/manual/Matching-tags-and-properties.html
                org_agenda_sorting_strategy = {
                  'priority-down',
                  'todo-state-down',
                }, -- See all options available on org_agenda_sorting_strategy
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
                org_agenda_sorting_strategy = {
                  'priority-down',
                  'todo-state-down',
                  'time-up',
                }, -- See all options available on org_agenda_sorting_strategy
              },
            },
          },
          p = {
            description = 'Project tasks',
            types = {
              {
                type = 'tags_todo',
                match = 'project',
                org_agenda_sorting_strategy = { 'todo-state-down', 'time-up' }, -- See all options available on org_agenda_sorting_strategy
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
            target = vim.g.env.notes.ORG_WORK,
            headline = 'work todo',
          },
          p = {
            description = 'purchase',
            template = '* TODO buy: %? :buy:\n  %U',
            target = vim.g.env.notes.ORG_PURCHASES,
            headline = 'purchases',
          },
          c = {
            description = 'quick capture',
            template = '* %?\n %U',
            target = vim.g.env.notes.ORG_REFILE,
          },
        },

        mappings = {
          agenda = {
            -- org_agenda_switch_to = false,
            -- org_agenda_goto = '<CR>',
          },
          org = {
            org_set_tags_command = nil,
            org_priority_up = '+',
            -- org_refile = false,
            -- org_agenda_set_tags = '<nop>',
            org_toggle_checkbox = '<leader><C-Space>',
            org_insert_todo_heading_respect_content = '<leader>tod',
            org_open_at_point = '<leader>oO',
          },
        },

        org_todo_keywords = {
          'TODO(t)', -- Tasks that are not started and not planned. They could be the backlogs or the GTD’s someday/maybe. These tasks could be converted to NEXT during a review.
          'NEXT(n)', -- Tasks that are not started but planned to do as soon as I can. When there is no actionable PROG (e.g., blocked), I start one of those and convert it to PROG.
          'PROG(p)', -- Tasks that are working in progress (open loops). I work on these tasks before starting another NEXT task to avoid too many open loops at any moment.
          '|', -- Hold up
          'CANC(c)', -- Tasks that have I've decided not to do.
          'DONE(d)', -- 😎👍
        },
      })

      vim.api.nvim_create_autocmd('FileType', {
        group = vim.api.nvim_create_augroup('celso-orgmode-filetype', { clear = true }),
        pattern = { 'org' },
        callback = function()
          vim.api.nvim_buf_set_keymap(
            0,
            'n',
            'gd',
            ':lua require("orgmode").action("org_mappings.open_at_point")<CR>',
            { desc = 'org:: toggle indent_mode' }
          )
        end,
      })

      if highlight then
        vim.schedule(set_highlights)
      end
    end,
  },
  {
    'akinsho/org-bullets.nvim',
    config = function()
      require('org-bullets').setup()
    end,
  },

  {
    'nvim-orgmode/telescope-orgmode.nvim',
    lazy = true,
    -- event = 'VeryLazy',
    dependencies = {
      'nvim-orgmode/orgmode',
      { 'nvim-telescope/telescope.nvim' },
    },
    config = function()
      require('telescope').load_extension('orgmode')
    end,

    keys = {
      {
        '<leader>re',
        function()
          require('telescope').extensions.orgmode.refile_heading()
        end,
        desc = 'org: refile heading',
      },
      {
        '<leader>os',
        function()
          require('telescope').extensions.orgmode.search_headings()
        end,
        desc = 'org: search headings',
      },
      {
        '<leader>toi',
        function()
          require('telescope').extensions.orgmode.insert_link()
        end,
        desc = 'org: insert link to heading',
      },
    },
  },

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
