return {
  {
    'celsobenedetti/zk-nvim',
    ft = 'markdown',
    keys = {
      { '<leader>n', ':ZkNewFromTitleSelection<CR>', mode = 'v' },
      { '<leader>zn', ':ZkNewFromTitleSelection<CR>', mode = 'v' },
      { '<leader>zz', ':ZkNotes<CR>' },
      { '<leader>zb', ':ZkBacklinks<CR>' },
      { '<leader>zt', ':ZkTags<CR>' },
      { '<leader>zm', ':ZkMatch<CR>', mode = 'v' },
      { '<leader>zl', ':ZkInsertLink<CR>' },
      { '<leader>zL', ':ZkLinks<CR>' },
      -- { '<leader>ch', ':norm @c<CR>', mode = 'v' },
      {
        '<leader>P',
        function()
          vim.api.nvim_feedkeys(Keys 'vip', 'n', true)
          local file_path = vim.fn.expand '%:p'
          if file_path:find 'html' then
            vim.api.nvim_feedkeys(Keys '!prettier --parser=html<CR>', 'n', true)
          else
            vim.api.nvim_feedkeys(Keys '!prettier --parser=markdown<CR>', 'n', true)
          end
        end,
        mode = 'n',
      },
      {
        '<leader>P',
        function()
          vim.api.nvim_feedkeys(Keys '!prettier --parser=markdown<CR>', 'n', true)
        end,
        mode = 'v',
      },
    },
    dependencies = {
      {
        'williamboman/mason.nvim',
        opts = function(_, opts)
          if type(opts.ensure_installed) == 'table' then
            vim.list_extend(opts.ensure_installed, { 'zk' })
          end
        end,
      },
    },

    config = function()
      require('zk').setup {
        picker = 'telescope',
      }

      map('n', '<leader>remove', function()
        vim.api.nvim_feedkeys(Keys ':!rm %<CR>', 'n', true)
        vim.api.nvim_feedkeys(Keys ':bdelete<cr>', 'n', true)
      end, { desc = 'rm buffer file' })

      vim.keymap.set('i', '<c-b>', function()
        vim.api.nvim_feedkeys(Keys '****<Esc>hha', 'n', true)
      end, { desc = 'Add bold tags for insert mode in bold' })

      vim.keymap.set('i', '<c-t>', function()
        vim.api.nvim_feedkeys(Keys '~~~~<Esc>hha', 'n', true)
      end, { desc = 'Add Strikeghrough italic tags for insert mode in bold' })
    end,
  },

  {
    'uga-rosa/cmp-dictionary',
    ft = { 'markdown', 'gitcommit' },
    config = function()
      require('cmp_dictionary').setup {
        exact_length = 2,
        paths = { '~/.dotfiles/english.dict' },
      }
    end,
  },
}
