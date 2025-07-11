return {

  {
    -- Slightly tint unfocused pane
    'levouh/tint.nvim',
    opts = {
      -- tint = -65, -- Darken colors, use a positive value to brighten
      -- saturation = 0.6, -- Saturation to preserve
      window_ignore_function = function(winid)
        local bufid = vim.api.nvim_win_get_buf(winid)
        local buftype = vim.api.nvim_buf_get_option(bufid, 'buftype')
        local floating = vim.api.nvim_win_get_config(winid).relative ~= ''

        return buftype == 'terminal'
          or 'nofile' -- used for namu
          or floating
      end,
    },
    lazy = C.opt.performance,
  },
}
