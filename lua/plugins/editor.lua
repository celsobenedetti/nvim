local navigate_tmux = function(cmd)
  return function()
    if not require('luasnip').in_snippet() then
      vim.cmd(cmd)
    end
  end
end

return {
  { 'numToStr/Comment.nvim', opts = {} }, -- "gc" to comment visual regions/lines
  { 'kylechui/nvim-surround', version = '*', config = true, vscode = true },

  {
    'christoomey/vim-tmux-navigator',
    keys = {
      { '<C-h>', navigate_tmux 'TmuxNavigateLeft', desc = 'Go to Left tmux pane' },
      { '<C-j>', navigate_tmux 'TmuxNavigateDown', desc = 'Go to Down tmux pane' },
      { '<C-k>', navigate_tmux 'TmuxNavigateUp', desc = 'Go to Up tmux pane' },
      { '<C-l>', navigate_tmux 'TmuxNavigateRight', desc = 'Go to Right tmux pane' },
    },
  },

  { -- Adds git related signs to the gutter, as well as utilities for managing changes
    'lewis6991/gitsigns.nvim',
    opts = {
      signs = {
        add = { text = '+' },
        change = { text = '~' },
        delete = { text = '_' },
        topdelete = { text = '‾' },
        changedelete = { text = '~' },
      },
    },
  },

  { -- Autoformat
    'stevearc/conform.nvim',
    opts = {
      notify_on_error = false,
      format_on_save = function()
        if not vim.g.autoformat then
          return
        end
        return { timeout_ms = 500, lsp_fallback = true }
      end,
      formatters_by_ft = {
        lua = { 'stylua' },
        python = { 'isort', 'black' },
        javascript = { { 'prettierd' } },
        markdown = { { 'prettierd' } },
      },
      formatters = {
        goimports = {
          prepend_args = { '-local', 'github.com/celsobenedetti/' },
        },
      },
    },
  },

  {
    'mbbill/undotree',
    keys = {
      { '<leader>U', '<cmd>UndotreeToggle<cr>', desc = 'Undotree Toggle' },
    },
    config = function()
      vim.opt.undodir = os.getenv 'HOME' .. '/.vim/undodir'
    end,
  },

  {
    'simrat39/symbols-outline.nvim',
    config = true,
    keys = {
      {
        '<leader>sO',
        function()
          require('symbols-outline').toggle_outline()
        end,
        desc = 'SymbolsOutline toggle',
      },
    },
  },

  {
    'danymat/neogen',
    dependencies = 'nvim-treesitter/nvim-treesitter',
    opts = {
      snippet_engine = 'luasnip',
    },
    keys = {
      {
        '<leader>A',
        ':Neogen<CR>',
        desc = 'Neogen annotation',
      },
    },
  },

  { -- Useful plugin to show you pending keybinds.
    'folke/which-key.nvim',
    event = 'VimEnter', -- Sets the loading event to 'VimEnter'
    config = function() -- This is the function that runs, AFTER loading
      require('which-key').setup()

      -- Document existing key chains
      require('which-key').register {
        ['<leader>c'] = { name = '[C]ode', _ = 'which_key_ignore' },
        ['<leader>d'] = { name = '[D]ocument', _ = 'which_key_ignore' },
        ['<leader>r'] = { name = '[R]ename', _ = 'which_key_ignore' },
        ['<leader>s'] = { name = '[S]earch', _ = 'which_key_ignore' },
        ['<leader>w'] = { name = '[W]orkspace', _ = 'which_key_ignore' },
      }
    end,
  },
}
