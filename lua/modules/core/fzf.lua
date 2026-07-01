return {
  'ibhagwan/fzf-lua',
  dependencies = { 'nvim-mini/mini.icons' },
  config = function()
    ---@module "fzf-lua"
    ---@type fzf-lua.Config|{}
    ---@diagnostic disable: missing-fields
    local opts = {}
    require('fzf-lua').setup(opts)

    vim.api.nvim_create_autocmd('FileType', {
      pattern = 'fzf',
      callback = function()
        vim.opt_local.number = false
        vim.opt_local.relativenumber = false
      end,
    })
  end,
  keys = {
    {
      '<c-p>',
      function()
        local cols = vim.o.columns
        local max_cols = 120
        require('fzf-lua').files({
          profile = 'fzf-vim',
          previewer = false,
          winopts = {
            height = 0.4,
            width = cols <= max_cols and 1.0 or (max_cols / cols),
          },
        })
      end,
    },

    {
      '<leader>zz',
      function()
        require('fzf-lua').files({
          cwd = '~/notes/obsidian/',
          profile = 'fzf-vim',
          previewer = false,
          winopts = { height = 0.4, width = 0.6 },
        })
      end,
    },
  },
}
