--- Global table
C = {
  opt = require 'core.config.options', --- Global options
  UI = require 'core.config.ui', --- Global UI config
  CWD = require 'lib.utils.cwd', --- Global CWD utils

  url = {
    linear = 'https://linear.app/celsobenedetti/team/C/cycle/active',
    linear_issue = 'https://linear.app/celsobenedetti/issue/',
    jira_issue = 'https://ocelotbot.atlassian.net/browse/',
    excalidraw = 'https://excalidraw.com',
    monkeytype = 'https://monkeytype.com',
  },
}

--- Global LSP utils
C.lsp = {
  ---@param on_attach fun(client:vim.lsp.Client, buffer)
  ---@param name? string
  on_attach = function(on_attach, name)
    return vim.api.nvim_create_autocmd('LspAttach', {
      callback = function(args)
        local buffer = args.buf ---@type number
        local client = vim.lsp.get_client_by_id(args.data.client_id)
        if client and (not name or client.name == name) then
          return on_attach(client, buffer)
        end
      end,
    })
  end,
}

C.utils = {
  get_visual_selection = require 'functions.utils.get_visual_selection',
}

-- iterate and validate all global variables
for key, value in pairs(C.opt) do
  if value == nil or value == '' then
    C.opt.key = ''
    print('WARN global variable not set:', key)
  end
end

C.opt.notes_path = C.opt.notes_path or ''
C.opt.gpt_chats_path = C.opt.notes_path .. '/local/chats' -- target directory for GPT chats.md files
