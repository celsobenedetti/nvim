if 'rose-pine-dawn' ~= require('lib.colors').omarchy_colorscheme().colorscheme then
  return {}
end

return {
  {
    'rose-pine/neovim',
    config = function()
      require('rose-pine').setup({
        highlight_groups = {
          TabLine = { bg = 'gold' },
          String = { fg = vim.g.colors.accent },
          ['@variable'] = { link = 'Normal' },
          ['@org.agenda.scheduled'] = { link = 'Normal' },
        },
      })

      local function hl_orgmode()
        vim.schedule(function()
          vim.api.nvim_set_hl(0, '@org.agenda.scheduled', { link = 'Normal' })
        end)
      end

      vim.api.nvim_create_autocmd('FileType', { pattern = 'org', callback = hl_orgmode })
      vim.api.nvim_create_autocmd('FileType', { pattern = 'orgagenda', callback = hl_orgmode })
    end,
  },
}
