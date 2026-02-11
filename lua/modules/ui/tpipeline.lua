return {
  {
    'vimpostor/vim-tpipeline',
    event = 'VeryLazy',
    init = function()
      vim.schedule(function()
        vim.cmd([[
        let g:tpipeline_autoembed = 0 "manually embed vimbridge in tmux conf"
        "let g:tpipeline_fillcentre = 1
        let g:tpipeline_clearstl = 1 "clear empty statusline"
        "set fcs=stlnc:─,stl:─,vert:│
      ]])
      end)
    end,
  },
}
