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
    opts = {
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
    },
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
