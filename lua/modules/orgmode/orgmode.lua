local colorschemes_to_highlight = {
  'koda',
  'rose-pine-dawn',
  'flexoki-light',
  'vantablack',
}
local TMP_CURRENT_TASK_FILE = '/tmp/org_current_task'

local agenda_files = {
  vim.g.env.notes.ORG .. '/*',
  vim.g.env.org.REFERENCES .. '/*',
  -- vim.g.env.org.INBOX,
  -- vim.g.env.org.MAIN,
  -- vim.g.env.org.WORK,
  -- vim.g.env.org.CALENDAR,
  -- vim.g.env.org.PURCHASES,
}

--- @type table<string, OrgAgendaCustomCommand>
local agenda_views = {
  T = {
    description = 'Engage',
    types = {
      {
        type = 'agenda',
        org_agenda_span = 'day',
        org_agenda_sorting_strategy = { 'time-up', 'todo-state-down', 'priority-down' },
      },
      {
        org_agenda_overriding_header = 'In Progress',
        type = 'tags_todo',
        match = 'TODO="PROG"',
        org_agenda_sorting_strategy = { 'priority-down', 'todo-state-down' },
      },
      {
        org_agenda_overriding_header = 'Next',
        type = 'tags_todo',
        match = 'TODO="NEXT"',
        org_agenda_sorting_strategy = { 'priority-down', 'todo-state-down' },
      },
      {
        org_agenda_overriding_header = 'Waiting',
        type = 'tags_todo',
        match = 'TODO="WAITING"',
        org_agenda_sorting_strategy = { 'priority-down', 'todo-state-down' },
      },
    },
  },

  n = {
    description = 'next',
    types = {
      {
        type = 'tags_todo',

        match = 'TODO="PROG"',
        org_agenda_sorting_strategy = { 'priority-down', 'todo-state-down' },
        org_agenda_overriding_header = 'In Progress',
      },
      {
        type = 'tags_todo',
        match = 'TODO="NEXT"',
        org_agenda_sorting_strategy = { 'priority-down', 'todo-state-down' },
        org_agenda_overriding_header = 'Next',
      },
      {
        type = 'tags_todo',
        match = 'TODO="WAITING"',
        org_agenda_sorting_strategy = { 'priority-down', 'todo-state-down' },
        org_agenda_overriding_header = 'Waiting',
      },
    },
  },
  t = {
    description = 'todo',
    types = {
      {
        type = 'tags_todo',

        match = '-TODO="DONE"',
        org_agenda_sorting_strategy = { 'todo-state-down' },
        org_agenda_overriding_header = 'In Progress',
      },
    },
  },

  d = {
    description = 'done',
    types = {
      {
        type = 'tags',
        match = '',
        org_agenda_sorting_strategy = { 'todo-state-down' },
        org_agenda_overriding_header = 'In Progress',
      },
    },
  },
  p = {
    description = 'purchases',
    types = { { type = 'tags_todo', match = 'buy', org_agenda_sorting_strategy = { 'time-up' } } },
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
        },
      },
    },
  },
  W = {
    description = 'WAITING',
    types = {
      {
        type = 'tags_todo', -- Type can be agenda | tags | tags_todo
        match = 'TODO="WAITING"', --Same as providing a "Match:" for tags view <leader>oa + m, See: https://orgmode.org/manual/Matching-tags-and-properties.html
        org_agenda_sorting_strategy = {
          'priority-down',
          'todo-state-down',
        }, -- See all options available on org_agenda_sorting_strategy
        -- org_agenda_overriding_header = 'High priority todos',
        -- org_agenda_todo_ignore_deadlines = 'far', -- Ignore all deadlines that are too far in future (over org_deadline_warning_days). Possible values: all | near | far | past | future
      },
    },
  },
  O = {
    description = 'ONGOING',
    types = {
      {
        type = 'tags_todo',
        match = 'TODO="ONGOING"', --Same as providing a "Match:" for tags view <leader>oa + m, See: https://orgmode.org/manual/Matching-tags-and-properties.html
        org_agenda_sorting_strategy = {
          'priority-down',
          'todo-state-down',
        }, -- See all options available on org_agenda_sorting_strategy
      },
    },
  },
  c = {
    description = 'calendar',
    types = {
      {
        type = 'tags_todo',
        match = 'TODO="UPCOMING"', --Same as providing a "Match:" for tags view <leader>oa + m, See: https://orgmode.org/manual/Matching-tags-and-properties.html
        org_agenda_sorting_strategy = {
          'priority-down',
          'todo-state-down',
        }, -- See all options available on org_agenda_sorting_strategy
      },
    },
  },
}

local function set_highlights()
  vim.api.nvim_set_hl(0, '@org.keyword.done', { link = '@comment.note' })
  vim.api.nvim_set_hl(0, '@org.keyword.todo', { link = '@comment.todo' })
  vim.api.nvim_set_hl(0, '@org.agenda.scheduled', { fg = 'gray' })
end

local function set_keymaps()
  -- TODO: can I figure out a way to parse the heading of the match location within the org file?
  vim.keymap.set('n', '<leader>sum', function()
    vim.ui.input({
      prompt = 'Get summary for date: (YYYY-MM-DD): ',
      default = tostring(os.date('%F')),
    }, function(selected_date)
      if not selected_date or selected_date == '' then
        return
      end

      local search_cmd = [[silent vimgrep /\(Note taken\|CLOSED\).*]] .. selected_date .. [[/gj 0\ org/*]]

      -- 2. Execute the search
      local ok, _ = pcall(vim.cmd, search_cmd)
      local qf_list = vim.fn.getqflist()
      if not ok or #qf_list == 0 then
        Snacks.notify.info('No matches found for: ' .. selected_date)
        vim.cmd('cclose') -- Close copen if it was open from a previous search but this one failed
        return
      end

      -- 3. Open the search results
      Snacks.notify.info('Found ' .. #qf_list .. ' matches.')
      vim.cmd('copen')
    end)
  end, { desc = 'org: search summary for day' })
end

return {
  {
    -- 'nvim-orgmode/orgmode',
    -- event = "VeryLazy",
    dir = '~/projects/nvim-orgmode-celsobenedetti/',
    dependencies = {
      -- { dir = '~/projects/nvim-orgmode-jira/', lazy = true },
      { 'celsobenedetti/orgmode-keymaps.nvim', config = true },
      { 'aaratha/org-cycle-lite.nvim' },
    },
    lazy = vim.g.lazy_orgmode == nil and true or vim.g.lazy_orgmode,
    cmd = { 'Org' },
    ft = { 'org', 'markdown' },
    keys = {
      { '<leader>oim', ':Org indent_mode<CR>', desc = 'org: toggle indent_mode' },
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
        org_agenda_files = agenda_files,
        org_agenda_sorting_strategy = { 'todo-state-up' },
        org_default_notes_file = vim.g.env.org.INBOX,
        org_priority_highest = 'A',
        org_priority_default = 'C',
        org_priority_lowest = 'C',
        org_log_into_drawer = 'LOGBOOK',
        org_ellipsis = ' ',
        org_startup_indented = true,
        org_adapt_indentation = false, -- left flush
        org_id_link_to_org_use_id = true,
        calendar_week_start_day = 0,
        -- org_agenda_start_on_weekday = 7, -- start on sunday
        notifications = { enabled = true },
        org_agenda_use_time_grid = false,
        org_deadline_warning_days = 7,
        org_agenda_custom_commands = agenda_views,
        org_blank_before_new_entry = { heading = true, plain_list_item = false },

        org_capture_templates = {
          c = {
            description = 'quick capture',
            template = '* %?',
            target = vim.g.env.org.INBOX,
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
          'TODO(t)', -- Actions that are not started and not planned. These are backlog.
          'UPCOMING(u)', -- Events that are upcoming, not actions to take.
          'ONGOING(o)', -- Ongoing projects/tasks that span multiple days, and should not be considered as actions.
          'NEXT(n)', -- Actions that are not started, but have been selected through planning to be engaged with next.
          'WAITING(w)', -- Acions that are waiting on some hold up or time to lapse.
          'PROG(p)', -- Actions that are currently WIP - these are the priorities.
          '|',
          'CANCELLED(c)', -- Actions that have not come to pass, or I have decided not to do.
          'DONE(d)', -- 😎👍
        },
      })

      -- orgmode plugins
      require('org-cycle-lite').setup({
        keymap = '<TAB>', -- Optional: change keymap
      })

      -- require('orgmode-jira').setup({
      --   base_url = os.getenv('WORK_JIRA_BASE_URL'),
      --   email = os.getenv('WORK_EMAIL'),
      --   api_token = os.getenv('JIRA_API_TOKEN'),
      -- })
      --
      local clock_in_current_task = function(ev)
        vim.g.org_current_task = ev.headline:get_title()
        local file = io.open(TMP_CURRENT_TASK_FILE, 'w')
        if file then
          file:write(ev.headline:get_title())
          file:write('\n' .. os.time())
          file:close()
        end
      end

      local Events = require('orgmode.events')
      Events.listen(Events.event.ClockedIn, function(ev)
        vim.schedule(clock_in_current_task)

        -- set to prog unless it's a log heading
        if not vim.iter(ev.headline:get_tags()):find(function(t)
          return t == 'log'
        end) then
          ev.headline:set_todo('PROG')
        end
      end)

      Events.listen(Events.event.ClockedOut, function(ev)
        vim.schedule(function()
          vim.g.org_current_task = nil
          os.remove(TMP_CURRENT_TASK_FILE)
        end)
      end)

      if vim.tbl_contains(colorschemes_to_highlight, require('lib.colors').omarchy_colorscheme().colorscheme) then
        vim.schedule(set_highlights)
      end
      vim.schedule(set_keymaps)
      vim.api.nvim_set_hl(0, '@org.headline.level1.org', { link = 'Special' })
    end,
  },

  {
    'nvim-orgmode/telescope-orgmode.nvim',
    lazy = true,
    -- event = 'VeryLazy',
    dependencies = {
      -- 'nvim-orgmode/orgmode',
      { 'nvim-telescope/telescope.nvim', lazy = true },
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
        '<leader>osh',
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
