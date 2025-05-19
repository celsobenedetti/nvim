return {
  { -- Fuzzy Finder (files, lsp, etc)
    'nvim-telescope/telescope.nvim',
    branch = '0.1.x',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'folke/trouble.nvim',
      { -- If encountering errors, see telescope-fzf-native README for install instructions
        'nvim-telescope/telescope-fzf-native.nvim',
        build = 'make',
      },
      { 'nvim-telescope/telescope-ui-select.nvim' },
      { 'nvim-tree/nvim-web-devicons' }, -- Useful for getting pretty icons, but requires a Nerd Font.
    },
    config = function()
      local ignore_patterns = {
        '^.git/',
        'node_modules',
        'pnpm-lock.yaml',
        'instascan.min.js',
      }

      local is_work = string.match(vim.fn.getcwd(), 'chatbot')
      if is_work then
        ignore_patterns = vim.list_extend(ignore_patterns, {
          'drupal',
          'python',
          -- 'terraform',
          -- 'nestjs',
          'packages/conversation/public/static',
          'public/static',
        })
      end

      local trouble = require 'trouble.sources.telescope'
      local my_actions = require 'functions.telescope.actions'

      require('telescope').setup {
        defaults = {
          file_ignore_patterns = ignore_patterns,
          mappings = {
            i = {
              ['<c-enter>'] = 'to_fuzzy_refine',
              ['<c-t>'] = trouble.open,
              ['<c-l>'] = my_actions.print_filepath_to_buffer,
            },
            n = {
              ['<c-t>'] = trouble.open,
            },
          },

          --- @param path string
          path_display = function(opts, path)
            local tail = require('telescope.utils').path_tail(path)
            return string.format('%s - %s', tail, path), { { { 1, #tail }, 'Constant' } }
          end,
        },
        pickers = {

          buffers = {
            mappings = {
              i = {
                ['<C-d>'] = require('telescope.actions').delete_buffer,
              },
            },
          },
        },
        extensions = {
          fzf = {},
          ['ui-select'] = {
            require('telescope.themes').get_dropdown(),
          },
        },
      }

      -- Enable telescope extensions, if they are installed
      pcall(require('telescope').load_extension, 'fzf')
      pcall(require('telescope').load_extension, 'ui-select')

      -- See `:help telescope.builtin`
      local builtin = require 'telescope.builtin'
      ---@diagnostic disable-next-line: different-requires

      map('n', '<leader>sh', builtin.help_tags, { desc = 'Telescope [S]earch [H]elp' })
      map('n', '<leader>sk', builtin.keymaps, { desc = 'Telescope [S]earch [K]eymaps' })
      map('n', '<leader>ff', builtin.find_files, { desc = 'Telescope [S]earch [F]iles' })
      map('n', '<leader>fF', builtin.git_files, { desc = 'Telescope [S]earch [F]iles' })
      map('n', '<leader>st', builtin.builtin, { desc = 'Telescope [S]earch [S]elect Telescope' })
      map('n', '<leader>sw', builtin.grep_string, { desc = 'Telescope [S]earch current [W]ord' })
      map('v', '<leader>sw', function()
        local selection = C.utils.get_visual_selection()
        if not selection then
          return
        end

        local cleaned_selection = string.gsub(selection, '\n$', '')
        builtin.grep_string { search = cleaned_selection }
      end, { desc = 'Telescope [S]earch current selection' })
      -- map('v', '<leader>sw', 'y<ESC>:Telescope grep_string search=<c-r>0<CR>')
      map('n', '<leader>gitb', builtin.git_branches, { desc = 'Telescope [S]earch [B]ranches' })
      map('n', '<leader><leader>', builtin.buffers, { desc = 'Telescope [S]earch [B]ranches' })
      map('n', '<leader>sH', '<cmd>Telescope highlights<cr>', { desc = 'Search Highlight Groups' })

      map('n', '<leader>sg', builtin.live_grep, { desc = 'Telescope [S]earch by [G]rep' })
      map('n', '<leader>sd', function()
        builtin.diagnostics { bufnr = 0 }
      end, { desc = 'Telescope [S]earch [D]iagnostics for Current Document' })
      map('n', '<leader>sD', builtin.diagnostics, { desc = 'Telescope [S]earch [D]iagnostics' })
      map('n', '<leader>sr', builtin.resume, { desc = 'Telescope [S]earch [R]esume' })
      map('n', '<leader>sn', builtin.treesitter, { desc = 'Telescope Find Treesitter nodes' })
      map('n', '<leader>sp', function()
        builtin.find_files { cwd = vim.fs.joinpath(vim.fn.stdpath 'data', 'lazy') }
      end, { desc = 'Telescope search app neovim plugin files ' })

      map('n', '<leader>/', builtin.current_buffer_fuzzy_find, { desc = '[/] Fuzzily search in current buffer' })

      map('n', '<leader>sc', require('telescope.builtin').commands, { desc = 'Telescope search commands' })
      map('n', '<leader>sC', require('telescope.builtin').command_history, { desc = 'Telescope search command history' })

      -- NOTE: make better use of this
      map('n', '<leader>gs', ':Telescope git_status<CR>', { desc = 'Telescope: [G]it Telescope [S]Status' })

      -- Also possible to pass additional configuration options.
      map('n', '<leader>s/', function()
        builtin.live_grep {
          grep_open_files = true,
          prompt_title = 'Live Grep in Open Files',
        }
      end, { desc = 'Telescope [S]earch [/] in Open Files' })

      -- Shortcut for searching your neovim configuration files
      map('n', '<leader>fv', function()
        builtin.find_files { cwd = vim.fn.stdpath 'config' }
      end, { desc = 'Telescope [S]earch [N]eovim files' })

      ------------- Custom functions ----------------------

      local functions = require 'functions.telescope'

      map('n', '<leader>mv', functions.move_file, { desc = 'Move file of current buffer to dir' })
      map('n', '<leader>dot', functions.dotfiles, { desc = 'Search Dotfiles' })
      map('n', '<leader>fn', functions.notes, { desc = 'Search Notes' })
      map('n', '<leader>s<leader>', functions.vertical_tabs, { desc = '[Telescope] Search crrent dir with vertical tabs mapping' })
    end,
  },

  {
    'nvim-telescope/telescope-live-grep-args.nvim',
    version = '^1.0.0',
    config = function()
      require('telescope').load_extension 'live_grep_args'
    end,
    keys = {
      {
        '<leader>sG',
        function()
          require('telescope').extensions.live_grep_args.live_grep_args()
        end,
        desc = 'Telescope grep with args',
      },
    },
  },
  {
    'benfowler/telescope-luasnip.nvim',
    config = function()
      require('telescope').load_extension 'luasnip'
    end,
    keys = {
      {
        '<leader>tl',
        ':Telescope luasnip<CR>',
        desc = 'Telescope grep with args',
      },
    },
  },
}
