local M = {}
--- Global LSP utils functions
M.lsp = {
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

return M
