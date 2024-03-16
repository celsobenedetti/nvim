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
      { 'nvim-tree/nvim-web-devicons', enabled = vim.g.have_nerd_font }, -- Useful for getting pretty icons, but requires a Nerd Font.
    },
    config = function()
      local trouble = require 'trouble.providers.telescope'
      require('telescope').setup {
        defaults = {
          mappings = {
            i = {
              ['<c-enter>'] = 'to_fuzzy_refine',
              ['<c-t>'] = trouble.open_with_trouble,
            },
            n = { ['<c-t>'] = trouble.open_with_trouble },
          },
        },
        -- pickers = {}
        extensions = {
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

      map('n', '<leader>sh', builtin.help_tags, { desc = '[S]earch [H]elp' })
      map('n', '<leader>sk', builtin.keymaps, { desc = '[S]earch [K]eymaps' })
      map('n', '<leader>ff', builtin.find_files, { desc = '[S]earch [F]iles' })
      map('n', '<leader>fF', builtin.git_files, { desc = '[S]earch [F]iles' })
      map('n', '<leader>st', builtin.builtin, { desc = '[S]earch [S]elect Telescope' })
      map('n', '<leader>sw', builtin.grep_string, { desc = '[S]earch current [W]ord' })
      map('v', '<leader>sw', 'y<ESC>:Telescope grep_string search=<c-r>0<CR>')

      map('n', '<leader>sg', builtin.live_grep, { desc = '[S]earch by [G]rep' })
      map('n', '<leader>sd', function()
        builtin.diagnostics { bufnr = 0 }
      end, { desc = '[S]earch [D]iagnostics for Current Document' })
      map('n', '<leader>sD', builtin.diagnostics, { desc = '[S]earch [D]iagnostics' })
      map('n', '<leader>sr', builtin.resume, { desc = '[S]earch [R]esume' })
      map('n', '<leader><leader>', require('c.functions.telescope.open_buffers').run, { desc = '[ ] Find existing buffers' })
      map('n', '<leader>sn', builtin.treesitter, { desc = 'Find Treesitter nodes' })

      map('n', '<leader>/', builtin.current_buffer_fuzzy_find, { desc = '[/] Fuzzily search in current buffer' })

      map('n', '<leader>sc', require('telescope.builtin').commands, { desc = 'Telescope search commands' })
      map('n', '<leader>sC', require('telescope.builtin').command_history, { desc = 'Telescope search command history' })

      -- Also possible to pass additional configuration options.
      map('n', '<leader>s/', function()
        builtin.live_grep {
          grep_open_files = true,
          prompt_title = 'Live Grep in Open Files',
        }
      end, { desc = '[S]earch [/] in Open Files' })

      -- Shortcut for searching your neovim configuration files
      map('n', '<leader>fv', function()
        builtin.find_files { cwd = vim.fn.stdpath 'config' }
      end, { desc = '[S]earch [N]eovim files' })

      ------------- Custom functions ----------------------

      local pickers = require 'telescope.pickers'
      local finders = require 'telescope.finders'
      local conf = require('telescope.config').values
      local actions = require 'telescope.actions'
      local action_state = require 'telescope.actions.state'

      local functions = {
        search_dotfiles = function()
          builtin.find_files {
            prompt_title = '< Dotfiles >',
            layout_config = {
              prompt_position = 'top',
            },
            sorting_strategy = 'ascending',
            search_dirs = {
              '~/.dotfiles',
            },
            hidden = true,
            find_command = { 'rg', '--files', '--hidden', '-g', '!.git' },
          }
        end,

        -- opens telescope with each subdirectory of ~/Documents/notes
        -- moves the current file to the selected directory
        move_note = function(opts)
          local fd = '!fd . --type=directory -E hugo/ ~/Documents/notes/'
          local fd_result = vim.api.nvim_exec2(fd, { output = true })

          local dirs = vim.split(fd_result.output, '\n')
          dirs = vim.tbl_filter(function(item)
            return item ~= '' and not string.match(item, '--type=directory')
          end, dirs)

          pickers
            .new({}, {
              prompt_title = 'Move file to directory',
              finder = finders.new_table {
                results = dirs,
              },
              sorter = conf.generic_sorter(opts),
              attach_mappings = function(prompt_bufnr, _)
                actions.select_default:replace(function()
                  actions.close(prompt_bufnr)
                  local selection = action_state.get_selected_entry()

                  local destination = selection[1]
                  if not destination then
                    return
                  end

                  local original_buffer = vim.api.nvim_get_current_buf()
                  vim.cmd('silent! !mv % ' .. destination)
                  vim.cmd('e ' .. destination .. '/' .. vim.fn.expand '%:t')
                  vim.api.nvim_buf_delete(original_buffer, { force = true })
                end)
                return true
              end,
            })
            :find()
        end,
      }
      -- Add custom
      map('n', '<leader>s.', functions.search_dotfiles, { desc = 'Search Dotfiles' })
      map('n', '<leader>mv', functions.move_note, { desc = 'Search Dotfiles' })
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
