local function is_tmux()
  local tmux = os.getenv('TMUX')
  return tmux and tmux ~= ''
end

return {

  'folke/snacks.nvim',
  keys = {
    {
      '<leader>uz',
      function()
        Snacks.zen({
          win = {
            style = {
              enter = true,
              fixbuf = false,
              minimal = true,
              width = math.floor(vim.go.columns * 0.7),
              height = 0,
              backdrop = { transparent = false, blend = 99 },
              keys = { q = false },
              zindex = 40,

              wo = {
                winhighlight = 'NormalFloat:Normal',
                number = false,
                relativenumber = false,
              },
              w = {
                snacks_main = true,
                lualine = false,
              },
            },
          },
        })
      end,
      desc = 'toggle Zen',
    },
  },
  opts = function(_, opts)
    --- @type snacks.zen.Config
    opts.zen = {
      on_open = function()
        vim.g.zen_mode = true

        vim.cmd('norm zt')

        if is_tmux() then
          vim.system({ 'tmux', 'set', 'status', 'off' }):wait()
        end
      end,
      on_close = function()
        vim.g.zen_mode = false
        if is_tmux() then
          vim.system({ 'tmux', 'set', 'status', 'on' }):wait()
        end
      end,
      show = {
        statusline = false, -- This hides the statusline (including lualine)
        tabline = false, -- This also hides the tabline
      },
      toggles = {
        dim = false,
        git_signs = false,
        snacks_main = true,
        snacks_indent = true,
        snacks = {
          indent = true,
        },
        -- diagnostics = false,
        -- inlay_hints = false,
      },
    }
  end,
}
