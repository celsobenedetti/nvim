-- return {
--   'nvim-treesitter/nvim-treesitter',
--   opts = {
--   },
-- }
--
return {

  -- Treesitter is a new parser generator tool that we can
  -- use in Neovim to power faster and more accurate
  -- syntax highlighting.
  {
    'nvim-treesitter/nvim-treesitter',
    branch = 'main',
    version = false, -- last release is way too old and doesn't work on Windows
    build = function()
      local TS = require 'nvim-treesitter'
      if not TS.get_installed then
        Snacks.notify.error 'Please restart Neovim and run `:TSUpdate` to use the `nvim-treesitter` **main** branch.'
        return
      end
      TS.update(nil, { summary = true })
    end,
    event = { 'VeryLazy' },
    cmd = { 'TSUpdate', 'TSInstall', 'TSLog', 'TSUninstall' },
    opts_extend = { 'ensure_installed' },
    opts = {
      indent = { enable = true },
      highlight = { enable = true },
      folds = { enable = true },
      ensure_installed = {
        'bash',
        'c',
        'diff',
        'html',
        'javascript',
        'jsdoc',
        'json',
        'jsonc',
        'lua',
        'luadoc',
        'luap',
        'markdown',
        'markdown_inline',
        'printf',
        'python',
        'query',
        'regex',
        'toml',
        'tsx',
        'typescript',
        'vim',
        'vimdoc',
        'vue',
        'xml',
        'yaml',
      },
    },
    config = function(_, opts)
      local TS = require 'nvim-treesitter'

      setmetatable(require 'nvim-treesitter.install', {
        __newindex = function(_, k)
          if k == 'compilers' then
            vim.schedule(function()
              Snacks.notify.error {
                'Setting custom compilers for `nvim-treesitter` is no longer supported.',
                '',
                'For more info, see:',
                '- [compilers](https://docs.rs/cc/latest/cc/#compile-time-requirements)',
              }
            end)
          end
        end,
      })

      -- some quick sanity checks
      if not TS.get_installed then
        return Snacks.notify.error 'Please use `:Lazy` and update `nvim-treesitter`'
      elseif type(opts.ensure_installed) ~= 'table' then
        return Snacks.notify.error '`nvim-treesitter` opts.ensure_installed must be a table'
      end

      -- setup treesitter
      TS.setup(opts)
      vim.wo.foldmethod = 'expr'
      vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
    end,
  },

  -- Automatically add closing tags for HTML and JSX
  {
    'windwp/nvim-ts-autotag',
    event = 'VeryLazy',
    opts = {},
  },

  {
    'nvim-treesitter/nvim-treesitter-context',
    event = 'VeryLazy',
    opts = function()
      local tsc = require 'treesitter-context'
      Snacks.toggle({
        name = 'Treesitter Context',
        get = tsc.enabled,
        set = function(state)
          if state then
            tsc.enable()
          else
            tsc.disable()
          end
        end,
      }):map '<leader>ut'
      return { mode = 'cursor', max_lines = 3 }
    end,
  },
}
