--- Runs cmd if not inside Luasnip snippet
---@param cmd string
local cmd = function(cmd)
  return function()
    if not require('luasnip').in_snippet() then
      vim.cmd(cmd)
    end
  end
end

return {
  { 'wakatime/vim-wakatime' }, -- code time tracking goodness
  { 'tpope/vim-sleuth' }, -- Detect tabstop and shiftwidth automatically
  { 'moll/vim-bbye' }, -- Delete buffers without affecting window layout :Bdelete
  { 'kylechui/nvim-surround', version = '*', config = true, vscode = true },

  {
    'numToStr/Comment.nvim',
    dependencies = {
      { 'JoosepAlviste/nvim-ts-context-commentstring' },
    },
    config = function()
      require('Comment').setup {
        pre_hook = require('ts_context_commentstring.integrations.comment_nvim').create_pre_hook(),
      }
    end,
  }, --  comment visual regions/lines

  {
    'christoomey/vim-tmux-navigator',
    keys = {
      { '<C-h>', cmd 'TmuxNavigateLeft', desc = 'Go to Left tmux pane' },
      { '<C-j>', cmd 'TmuxNavigateDown', desc = 'Go to Down tmux pane' },
      { '<C-k>', cmd 'TmuxNavigateUp', desc = 'Go to Up tmux pane' },
      { '<C-l>', cmd 'TmuxNavigateRight', desc = 'Go to Right tmux pane' },
    },
  },

  {
    'mbbill/undotree',
    lazy = false,
    keys = { { '<leader>U', '<cmd>UndotreeToggle<cr>', desc = 'Undotree Toggle' } },
    config = function()
      vim.opt.undodir = os.getenv 'HOME' .. '/.vim/undodir'
    end,
  },

  {
    'hedyhli/outline.nvim',
    lazy = true,
    cmd = { 'Outline', 'OutlineOpen' },
    keys = {
      { '<leader>o', '<cmd>Outline<CR>', desc = 'Toggle outline' },
    },
    opts = {},
  },

  {
    'danymat/neogen',
    dependencies = 'nvim-treesitter/nvim-treesitter',
    opts = {
      snippet_engine = 'luasnip',
    },
    keys = {
      {
        '<leader>an',
        ':Neogen<CR>',
        desc = 'Neogen annotation',
      },
    },
  },

  -- search/replace in multiple files
  {
    'nvim-pack/nvim-spectre',
    build = false,
    cmd = 'Spectre',
    opts = { open_cmd = 'noswapfile vnew' },
    -- stylua: ignore
    keys = {
      { "<leader>sed", function() require("spectre").open() end, desc = "Replace in files (Spectre)" },
    },
  },

  -- { -- Useful plugin to show you pending keybinds.
  --   'folke/which-key.nvim',
  --   event = 'VimEnter', -- Sets the loading event to 'VimEnter'
  --   config = function() -- This is the function that runs, AFTER loading
  --     require('which-key').setup()
  --
  --     -- Document existing key chains
  --     require('which-key').register {
  --       ['<leader>c'] = { name = '[C]ode', _ = 'which_key_ignore' },
  --       ['<leader>d'] = { name = '[D]ocument', _ = 'which_key_ignore' },
  --       ['<leader>r'] = { name = '[R]ename', _ = 'which_key_ignore' },
  --       ['<leader>s'] = { name = '[S]earch', _ = 'which_key_ignore' },
  --       ['<leader>w'] = { name = '[W]orkspace', _ = 'which_key_ignore' },
  --     }
  --   end,
  -- },
}
