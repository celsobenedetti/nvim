return {
  { -- Collection of various small independent plugins/modules
    'echasnovski/mini.nvim',
    config = function()
      --  - va)  - [V]isually select [A]round [)]paren
      --  - yinq - [Y]ank [I]nside [N]ext [']quote
      --  - ci'  - [C]hange [I]nside [']quote
      require('mini.ai').setup { n_lines = 500 }
    end,
  },
  {
    'echasnovski/mini.files',
    version = '*',
    enabled = false, -- WIP: lets try yazi.nvim instead
    lazy = true,
    config = function()
      local MiniFiles = require 'mini.files'
      MiniFiles.setup {
        mappings = {
          close = 'q',
          go_in = 'L',
          go_out = 'H',
          go_in_plus = '<C-l>',
          go_out_plus = '<C-h>',
          reset = '<BS>',
          reveal_cwd = '@',
          show_help = 'g?',
          synchronize = '<C-y>',
          trim_left = '<',
          trim_right = '>',
        },
        options = {
          use_as_default_explorer = true,
        },
        windows = {
          -- Maximum number of windows to show side by side
          max_number = math.huge,
          -- Whether to show preview of file/directory under cursor
          preview = true,
          -- Width of focused window
          width_focus = 50,
          -- Width of non-focused window
          width_nofocus = 15,
          -- Width of preview window
          width_preview = 100,
        },
      }

      local map_split = function(buf_id, lhs, direction)
        local rhs = function()
          -- Make new window and set it as target
          local cur_target = MiniFiles.get_explorer_state().target_window
          local new_target = vim.api.nvim_win_call(cur_target, function()
            vim.cmd(direction .. ' split')
            return vim.api.nvim_get_current_win()
          end)

          MiniFiles.set_target_window(new_target)

          -- This intentionally doesn't act on file under cursor in favor of
          -- explicit "go in" action (`l` / `L`). To immediately open file,
          -- add appropriate `MiniFiles.go_in()` call instead of this comment.
        end

        -- Adding `desc` will result into `show_help` entries
        local desc = 'Split ' .. direction
        vim.keymap.set('n', lhs, rhs, { buffer = buf_id, desc = desc })
      end

      -- vim.api.nvim_create_autocmd('User', {
      --   pattern = 'MiniFilesBufferCreate',
      --   callback = function(args)
      --     local buf_id = args.data.buf_id
      --     -- Tweak keys to your liking
      --     map_split(buf_id, '<C-s>', 'belowright horizontal')
      --     map_split(buf_id, '<C-v>', 'belowright vertical')
      --   end,
      -- })
    end,
    keys = {
      {
        '<leader>fm',
        function()
          require('mini.files').open(vim.api.nvim_buf_get_name(0), true)
        end,
        desc = 'Open mini.files (directory of current file)',
      },
      {
        '<leader>fM',
        function()
          require('mini.files').open(vim.loop.cwd(), true)
        end,
        desc = 'Open mini.files (cwd)',
      },
    },
  },
}
