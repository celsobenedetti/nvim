local lsp = {
  action = setmetatable({}, {
    __index = function(_, action)
      return function()
        vim.lsp.buf.code_action {
          apply = true,
          context = {
            only = { action },
            diagnostics = {},
          },
        }
      end
    end,
  }),

  ---@class LspCommand: lsp.ExecuteCommandParams
  ---@field open? boolean
  ---@field handler? lsp.Handler

  ---@param opts LspCommand
  execute = function(opts)
    local params = {
      command = opts.command,
      arguments = opts.arguments,
    }
    if opts.open then
      require('trouble').open {
        mode = 'lsp_command',
        params = params,
      }
    else
      return vim.lsp.buf_request(0, 'workspace/executeCommand', params, opts.handler)
    end
  end,
}

return {
  on_init = function()
    vim.keymap.set('n', '<leader>ami', lsp.action['source.addMissingImports.ts'], {
      desc = 'Add missing imports',
    })
    vim.keymap.set('n', 'gD', function()
      local win = vim.api.nvim_get_current_win()
      local params = vim.lsp.util.make_position_params(win, 'utf-16')
      lsp.execute {
        command = 'typescript.goToSourceDefinition',
        arguments = { params.textDocument.uri, params.position },
        open = true,
      }
    end, {
      desc = 'Goto Source Definition',
    })
    vim.keymap.set('n', 'gR', function()
      lsp.execute {
        command = 'typescript.findAllFileReferences',
        arguments = { vim.uri_from_bufnr(0) },
        open = true,
      }
    end, {
      desc = 'File References',
    })
    vim.keymap.set('n', '<leader>oi', lsp.action['source.organizeImports'], {
      desc = 'Organize Imports',
    })
    vim.keymap.set('n', '<leader>ru', lsp.action['source.removeUnused.ts'], {
      desc = 'Remove unused imports',
    })
    vim.keymap.set('n', '<leader>fa', lsp.action['source.fixAll.ts'], {
      desc = 'Fix all diagnostics',
    })
    vim.keymap.set('n', '<leader>cV', function()
      lsp.execute { command = 'typescript.selectTypeScriptVersion' }
    end, {
      desc = 'Select TS workspace version',
    })
  end,
}
