return {
  {
    'kristijanhusak/vim-dadbod-ui',
    dependencies = {
      { 'tpope/vim-dadbod',                     lazy = true },
      { 'kristijanhusak/vim-dadbod-completion', ft = { 'sql', 'mysql', 'plsql' }, lazy = true },
    },
    cmd = {
      'DBUI',
      'DBUIToggle',
      'DBUIAddConnection',
      'DBUIFindBuffer',
    },
    init = function()
      -- Your DBUI configuration
      vim.g.db_ui_use_nerd_fonts = 1

      vim.api.nvim_create_user_command('Db', function(opts)
        local tabname = opts.args
        if not tabname or tabname == '' then
          tabname = vim.fn.input('Tab name: ')
        end

        if tabname == '' then
          return
        end

        vim.cmd.tabnew()
        vim.cmd('DBUI')
        tabname = config.icons.db .. tabname
        lib.tab.rename(tabname)
      end, { nargs = 1 })

      -- vim.cmd.cnoreabbrev('db Db')
      -- vim.cmd.cnoreabbrev('DB Db')
    end,
  },
}
