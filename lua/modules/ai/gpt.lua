return {
  {
    'robitx/gp.nvim',
    cmd = {
      'GpChatNew',
    },
    keys = {
      {
        '<leader>G',
        ':GpChatNew vsplit<CR>',
        desc = 'Open ChatGPT in vertical split',
      },
    },
    config = function(opts)
      opts.chat_dir = C.opt.gpt_chats_path
      require('gp').setup(opts)
    end,
  },
}
