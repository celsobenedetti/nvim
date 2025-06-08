if true then
  return {}
end

-- NOTE: the startup commands is slow, I'm disabling it

return {
  'goolord/alpha-nvim',
  enabled = false,
  dependencies = {
    'juansalvatore/git-dashboard-nvim',
  },
  event = 'VimEnter',
  config = function()
    local lazy = require 'lazy'
    local alpha = require 'alpha'

    local git_dashboard = require('git-dashboard-nvim').setup {
      top_padding = 8,
      bottom_padding = 2,
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
        dashboard_title = C.ui.colors.pink,
        days_and_months_labels = C.ui.colors.green,
        empty_square_highlight = C.ui.colors.green,
        filled_square_highlights = {
          C.ui.colors.lime,
          C.ui.colors.aqua,
          C.ui.colors.skye,
          C.ui.colors.snow,
          C.ui.colors.purple,
          C.ui.colors.green,
        },
        branch_highlight = C.ui.colors.pink,
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
        button('r', 'recent files', ':Telescope oldfiles <CR>', { icon = '', hl = { { 'Function', 1, 2 }, { 'Normal', 3, 52 } } }),
        button('f', 'find file', ':Telescope find_files<CR>', { icon = '󰱼', hl = { { 'Function', 1, 2 }, { 'Normal', 3, 52 } } }),

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
        button('a', 'agenda', function()
          vim.cmd 'e ~/notes/orgfiles/i.org'
          vim.cmd 'Org agenda a'
        end, { icon = '󰃭', hl = { { 'Float', 1, 2 }, { 'Normal', 3, 52 } } }),
        button('t', 'today', function()
          vim.cmd 'e ~/notes/orgfiles/i.org'
          vim.cmd 'Org agenda T'
        end, { icon = '', hl = { { 'Float', 1, 2 }, { 'Normal', 3, 52 } } }),
        button('o', 'org files', require('lib.functions.telescope').org_files, { icon = '', hl = { { 'Float', 1, 2 }, { 'Normal', 3, 52 } } }),

        button('g', 'gpt', ':GpChatNew<CR>', { icon = '', hl = { { 'Float', 1, 2 }, { 'Normal', 3, 52 } } }),

        button('y', 'yazi', function()
          vim.cmd 'Yazi'
        end, { icon = '', hl = { { 'Function', 1, 2 }, { 'Normal', 3, 52 } } }),

        button('l', 'git log', function()
          Snacks.lazygit.log()
        end, { icon = '', hl = { { 'Function', 1, 2 }, { 'Normal', 3, 52 } } }),

        button('q', 'quit', ':qa<CR>', { icon = '', hl = { { 'Comment', 1, 2 }, { 'Normal', 3, 52 } } }),
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
