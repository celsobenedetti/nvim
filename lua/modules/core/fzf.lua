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
          profile = 'ivy',
          fzf_opts = {
            ['--layout'] = 'default',
          },
        })
      end,
    },
  },
}
