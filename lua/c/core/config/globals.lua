C = {
  global = require 'c.core.config.options',

  UI = require 'c.core.config.ui',
}

C.CWD = require 'c.lib.utils.cwd'

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

-- iterate and validate all global variables
for key, value in pairs(C.global) do
  if value == nil or value == '' then
    C.global.key = ''
    print('WARN global variable not set:', key)
  end
end

C.global.notes_path = C.global.notes_path or ''
C.global.gpt_chats_path = C.global.notes_path .. './local/chats' -- target directory for GPT chats.md files
