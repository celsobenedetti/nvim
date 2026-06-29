return {
  'ibhagwan/fzf-lua',
  dependencies = { 'nvim-mini/mini.icons' },
  config = function()
    ---@module "fzf-lua"
    ---@type fzf-lua.Config|{}
    ---@diagnostic disable: missing-fields
    local opts = {}
    require('fzf-lua').setup(opts)
  end,
  keys = {
    {
      '<c-p>',
      function()
        require('fzf-lua').files({
          profile = 'fzf-vim',
          previewer = false,
          winopts = { height = 0.4, width = 0.6 },
        })
      end,
    },
  },
}
