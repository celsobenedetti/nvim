return {
  {
    'nvim-orgmode/orgmode', -- event = 'VeryLazy',
    ft = { 'org' },
    keys = {
      {
        '<leader>oaa',
        ':Org agenda a<CR>',
        desc = 'Org agenda week',
      },
    },
    config = function()
      -- Setup orgmode
      require('orgmode').setup {
        org_agenda_files = '~/notes/orgfiles/**/*',
        org_default_notes_file = '~/notes/orgfiles/refile.org',
      }

      -- NOTE: If you are using nvim-treesitter with ~ensure_installed = "all"~ option
      -- add ~org~ to ignore_install
      -- require('nvim-treesitter.configs').setup {
      --   ensure_installed = 'all',
      --   ignore_install = { 'org' },
      -- }
    end,
  },

  {
    'nvim-orgmode/telescope-orgmode.nvim',
    event = 'VeryLazy',
    dependencies = {
      'nvim-orgmode/orgmode',
      'nvim-telescope/telescope.nvim',
    },
    config = function()
      require('telescope').load_extension 'orgmode'
    end,

    keys = {
      {
        '<leader>tor',
        function()
          require('telescope').extensions.orgmode.refile_heading()
        end,
        desc = 'Telescope Orgmode refile_heading',
      },
      {
        '<leader>tos',
        function()
          require('telescope').extensions.orgmode.search_headings()
        end,
        desc = 'Telescope Orgmode search_headings',
      },
      {
        '<leader>toi',
        function()
          require('telescope').extensions.orgmode.insert_link()
        end,
        desc = 'Telescope Orgmode insert_link',
      },
    },
  },
}
