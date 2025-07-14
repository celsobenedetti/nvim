local enabled_servers = {
  'gopls',
  'lua_ls',
  'vtsls',
  'vue_ls',
}

local getConfigs = function()
  local vue_language_server_path = vim.fn.stdpath 'data' .. '/mason/packages/vue-language-server/node_modules/@vue/language-server'
  local vue_plugin = {
    name = '@vue/typescript-plugin',
    location = vue_language_server_path,
    languages = { 'vue' },
    configNamespace = 'typescript',
  }

  local configs = {
    luals = {
      settings = {
        Lua = {
          runtime = { version = 'LuaJIT' },
          workspace = {
            checkThirdParty = false,
            library = {
              vim.env.VIMRUNTIME,
              -- Depending on the usage, you might want to add additional paths here.
              -- "${3rd}/luv/library"
              -- "${3rd}/busted/library",
              -- '${3rd}/luv/library',
              -- unpack(vim.api.nvim_get_runtime_file('', true)),
            },
          },
          completion = {
            callSnippet = 'Replace',
          },
          -- diagnostics = { disable = { 'missing-fields' } }, -- Toggle to supress specific warnings
        },
      },
    },

    vue_ls = {
      on_init = function(client)
        client.handlers['tsserver/request'] = function(_, result, context)
          local clients = vim.lsp.get_clients { bufnr = context.bufnr, name = 'vtsls' }
          if #clients == 0 then
            vim.notify('Could not find `vtsls` lsp client, `vue_ls` would not work without it.', vim.log.levels.ERROR)
            return
          end
          local ts_client = clients[1]

          local param = unpack(result)
          local id, command, payload = unpack(param)
          ts_client:exec_cmd({
            title = 'vue_request_forward', -- You can give title anything as it's used to represent a command in the UI, `:h Client:exec_cmd`
            command = 'typescript.tsserverRequest',
            arguments = {
              command,
              payload,
            },
          }, { bufnr = context.bufnr }, function(_, r)
            local response_data = { { id, r.body } }
            ---@diagnostic disable-next-line: param-type-mismatch
            client:notify('tsserver/response', response_data)
          end)
        end
      end,
    },

    vtsls = {
      settings = {
        vtsls = {
          tsserver = {
            globalPlugins = {
              vue_plugin,
            },
          },
        },
      },
      filetypes = { 'typescript', 'javascript', 'javascriptreact', 'typescriptreact', 'vue' },
    },

    -- jsonls = {
    --   on_new_config = function(new_config)
    --     new_config.settings.json.schemas = new_config.settings.json.schemas or {}
    --     vim.list_extend(new_config.settings.json.schemas, require('schemastore').json.schemas())
    --   end,
    --   settings = {
    --     json = {
    --       validate = { enable = true },
    --     },
    --   },
    -- },
    --
    -- yamlls = {
    --   settings = {
    --     yaml = {
    --       schemaStore = {
    --         -- You must disable built-in schemaStore support if you want to use
    --         -- this plugin and its advanced options like `ignore`.
    --         enable = false,
    --         -- Avoid TypeError: Cannot read properties of undefined (reading 'length')
    --         url = '',
    --       },
    --       schemas = require('schemastore').yaml.schemas(),
    --     },
    --   },
    -- },
  }
  return configs
end

return {
  { -- LSP Configuration & Plugins
    'neovim/nvim-lspconfig',
    dependencies = {
      -- Automatically install LSPs and related tools to stdpath for neovim
      'williamboman/mason.nvim',
      -- 'williamboman/mason-lspconfig.nvim',
      'WhoIsSethDaniel/mason-tool-installer.nvim',
      { 'b0o/schemastore.nvim', lazy = true },
      { 'j-hui/fidget.nvim', opts = {} }, -- Useful status updates for LSP.
    },

    config = function()
      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('kickstart-lsp-attach', { clear = true }),
        callback = function(event)
          -- In this case, we create a function that lets us more easily define mappings specific
          -- for LSP related items. It sets the mode, buffer and description for us each time.
          local lsp_map = function(mode, keys, func, desc)
            map(mode, keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
          end

          -- diagnostic
          local diagnostic_goto = function(next, severity)
            -- set mark to jump list before moving to next/prev diagnostic
            vim.api.nvim_feedkeys("m'", 'n', true)
            severity = severity and vim.diagnostic.severity[severity] or nil
            return function()
              vim.diagnostic.jump {
                -- severity = severity,
                count = next and 1 or -1,
                float = true,
              }
            end
          end

          lsp_map('n', ']d', diagnostic_goto(true), 'Next Diagnostic')
          lsp_map('n', '[d', diagnostic_goto(false), 'Prev Diagnostic')
          lsp_map('n', ']e', diagnostic_goto(true, 'ERROR'), 'Next Error')
          lsp_map('n', '[e', diagnostic_goto(false, 'ERROR'), 'Prev Error')
          lsp_map('n', ']w', diagnostic_goto(true, 'WARN'), 'Next Warning')
          lsp_map('n', '[w', diagnostic_goto(false, 'WARN'), 'Prev Warning')
          lsp_map('n', 'gd', require('telescope.builtin').lsp_definitions, '[G]oto [D]efinition')
          lsp_map('n', 'gr', require('telescope.builtin').lsp_references, '[G]oto [R]eferences')

          -- TODO: cleanup comments about default nvim keymaps once I get used to them
          -- not needed, default nvim keymap is gri
          lsp_map('n', 'gI', require('telescope.builtin').lsp_implementations, '[G]oto [I]mplementation')

          -- default vim gO
          lsp_map('n', '<leader>ss', require('telescope.builtin').lsp_document_symbols, '[D]ocument [S]ymbols')
          lsp_map('n', '<leader>sS', require('telescope.builtin').lsp_dynamic_workspace_symbols, '[W]orkspace [S]ymbols')
          -- lsp_map('n', '<leader>rn', vim.lsp.buf.rename, '[R]e[n]ame') -- not needed, default nvim keymap is grn
          -- lsp_map('n', '<leader>ca', vim.lsp.buf.code_action, '[C]ode [A]ction') -- not needed, default nvim keymap is gra
          -- lsp_map('v', '<leader>ca', vim.lsp.buf.code_action, 'LSP: [C]ode [A]ction')
          lsp_map('n', 'K', vim.lsp.buf.hover, 'Hover Documentation')
          lsp_map('n', 'gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')
          lsp_map('n', 'gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')

          -- default nvim keymap <C-s>: vim.lsp.buf.signature_help()

          -- The following two autocommands are used to highlight references of the
          -- word under your cursor when your cursor rests there for a little while.
          --    See `:help CursorHold` for information about when this is executed
          --
          -- When you move your cursor, the highlights will be cleared (the second autocommand).
          local client = vim.lsp.get_client_by_id(event.data.client_id)
          if client and client.server_capabilities.documentHighlightProvider then
            vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
              buffer = event.buf,
              callback = vim.lsp.buf.document_highlight,
            })

            vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
              buffer = event.buf,
              callback = vim.lsp.buf.clear_references,
            })
          end
        end,
      })

      local configs = getConfigs()
      vim.lsp.config('vtsls', configs.vtsls)
      vim.lsp.config('gopls', {})
      vim.lsp.config('vue_ls', configs.vue_ls)
      vim.lsp.config('lua_ls', configs.luals)
      vim.lsp.config('tailwindcss', {})
      vim.lsp.enable(enabled_servers)

      vim.diagnostic.config {
        virtual_text = false,
        float = { border = 'rounded', source = true },
      }
    end,
  },
}
