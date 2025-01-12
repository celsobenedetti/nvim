return {
  {
    'robitx/gp.nvim',
    cmd = {
      'GpChatNew',
    },
    keys = {
      {
        '<leader>G',
        ':GpChatNew tabnew<CR>',
        desc = 'Open ChatGPT in new tab',
      },
    },
    config = function(opts)
      opts.chat_dir = C.opt.gpt_chats_path
      require('gp').setup(opts)
    end,
  },
}
