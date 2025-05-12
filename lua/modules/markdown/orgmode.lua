return {
  'nvim-orgmode/orgmode',
  -- event = 'VeryLazy',
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
}
