return {
  'goolord/alpha-nvim',
  dependencies = {
    'juansalvatore/git-dashboard-nvim',
  },
  event = 'VimEnter',
  config = function()
    local lazy = require 'lazy'
    local alpha = require 'alpha'

    local git_dashboard = require('git-dashboard-nvim').setup {
      top_padding = 0,
      bottom_padding = 0,
      show_current_branch = true,
      hide_cursor = false,
      centered = false,
      branch = { 'master', 'main' },
      use_git_username_as_author = true,
      -- show_only_weeks_with_commits = true,
      is_horizontal = true,
      day_label_gap = '   ',
      gap = '  ',
      empty_square = '',
      filled_squares = { '', '', '', '', '', '' },
      basepoints = { 'master', 'main' },
      colors = {
        days_and_months_labels = '#88C0D0',
        empty_square_highlight = '#6098A7',
        filled_square_highlights = { '#002C39', '#094D5B', '#387180', '#6098A7', '#88C0D0', '#C0FAFF' },
        branch_highlight = '#ffc3fa',
        dashboard_title = '#88C0D0',
      },
    }

    local function surround(v)
      return ' ' .. v .. ' '
    end

    local function info_value()
      local total_plugins = lazy.stats().count
      local loaded_plugins = lazy.stats().loaded
      local version = vim.version()
      local nvim_version_info = ' ' .. version.major .. '.' .. version.minor .. '.' .. version.patch

      return surround '' .. total_plugins .. '/' .. loaded_plugins .. ' plugins loaded ' .. nvim_version_info
    end

    local heatmap = {

      type = 'text',
      val = git_dashboard,
      opts = {
        position = 'center',
      },
    }

    local info = {
      type = 'text',
      val = info_value(),
      opts = {
        hl = 'Function',
        position = 'center',
      },
    }

    local function button(lhs, txt, rhs, opts)
      lhs = lhs:gsub('%s', ''):gsub('SPC', '<leader>')

      local default_opts = {
        position = 'center',
        shortcut = '[' .. lhs .. '] ',
        cursor = 1,
        width = 60,
        align_shortcut = 'left',
        hl_shortcut = { { 'Keyword', 0, 1 }, { 'Function', 1, #lhs + 1 }, { 'Keyword', #lhs + 1, #lhs + 2 } },
        shrink_margin = false,
        keymap = { 'n', lhs, rhs, { noremap = true, silent = true, nowait = true } },
      }

      opts = vim.tbl_deep_extend('force', default_opts, opts or {})

      return {
        type = 'button',
        val = string.format(' %-1s  %s', opts.icon or '', txt),
        on_press = function()
          local key = vim.api.nvim_replace_termcodes(rhs .. '<Ignore>', true, false, true)
          vim.api.nvim_feedkeys(key, 't', false)
        end,
        opts = opts,
      }
    end

    local buttons = {
      type = 'group',
      val = {
        { type = 'padding', val = 1 },
        {
          type = 'text',
          val = string.rep('─', 50),
          opts = {
            -- hl = 'FloatBorder',
            position = 'center',
          },
        },
        { type = 'padding', val = 1 },
        button('r', 'Recently used files', ':Telescope oldfiles <CR>', { icon = '', hl = { { 'Function', 1, 2 }, { 'Normal', 3, 52 } } }),
        button('f', 'Find File', ':Telescope find_files<CR>', { icon = '󰱼', hl = { { 'Function', 1, 2 }, { 'Normal', 3, 52 } } }),

        -- button(
        --   'p',
        --   'Find Project',
        --   ":lua require('telescope').extensions.projects.projects{}<CR>",
        --   { icon = '', hl = { { 'Error', 1, 2 }, { 'Normal', 3, 52 } } }
        -- ),
        -- button(
        --   'e',
        --   'Restore Session',
        --   ":lua require('persistence').load({ last = true})<CR>",
        --   { icon = '󰦛', hl = { { 'String', 1, 2 }, { 'Normal', 3, 52 } } }
        -- ),
        button('a', 'Agenda', ':Org agenda a<CR>', { icon = '󰃭', hl = { { 'Float', 1, 2 }, { 'Normal', 3, 52 } } }),
        button('t', 'Today', ':Org agenda t<CR>', { icon = '', hl = { { 'Float', 1, 2 }, { 'Normal', 3, 52 } } }),

        button('n', 'Notes', function()
          require('functions.telescope').notes()
        end, { icon = '', hl = { { 'Float', 1, 2 }, { 'Normal', 3, 52 } } }),
        button('g', 'GPT', ':GpChatNew<CR>', { icon = '', hl = { { 'Float', 1, 2 }, { 'Normal', 3, 52 } } }),
        button('i', 'Orgmode index', ':e ~/notes/orgfiles/i.org<cr>', { icon = '', hl = { { 'Float', 1, 2 }, { 'Normal', 3, 52 } } }),
        button('.', 'Dotfiles', function()
          require('functions.telescope').dotfiles()
        end, { icon = '', hl = { { 'diffLine', 1, 2 }, { 'Normal', 3, 52 } } }),
        button('m', 'Marks', ':Telescope marks <CR>', { icon = '', hl = { { 'Function', 1, 2 }, { 'Normal', 3, 52 } } }),
        button('q', 'Quit', ':qa<CR>', { icon = '', hl = { { 'Comment', 1, 2 }, { 'Normal', 3, 52 } } }),
        { type = 'padding', val = 1 },
        {
          type = 'text',
          val = string.rep('─', 50),
          opts = {
            -- hl = 'FloatBorder',
            position = 'center',
          },
        },
      },
    }

    local config = {
      layout = {
        { type = 'padding', val = 3 },
        heatmap,
        buttons,
        { type = 'padding', val = 2 },
        info,
      },
    }

    alpha.setup(config)
  end,
}
