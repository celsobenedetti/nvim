local getServerConfigs = function()
  return {
    -- deno = {},
    dockerls = {},
    gopls = {},
    graphql = {},
    pyright = {},
    tailwindcss = {},
    terraformls = {},
    tsserver = {},
    -- vtsls = {},

    lua_ls = {
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

    jsonls = {
      on_new_config = function(new_config)
        new_config.settings.json.schemas = new_config.settings.json.schemas or {}
        vim.list_extend(new_config.settings.json.schemas, require('schemastore').json.schemas())
      end,
      settings = {
        json = {
          validate = { enable = true },
        },
      },
    },

    yamlls = {
      settings = {
        yaml = {
          schemaStore = {
            -- You must disable built-in schemaStore support if you want to use
            -- this plugin and its advanced options like `ignore`.
            enable = false,
            -- Avoid TypeError: Cannot read properties of undefined (reading 'length')
            url = '',
          },
          schemas = require('schemastore').yaml.schemas(),
        },
      },
    },
  }
end
return {
  { -- LSP Configuration & Plugins
    'neovim/nvim-lspconfig',
    dependencies = {
      -- Automatically install LSPs and related tools to stdpath for neovim
      'williamboman/mason.nvim',
      'williamboman/mason-lspconfig.nvim',
      'WhoIsSethDaniel/mason-tool-installer.nvim',

      { 'b0o/schemastore.nvim', lazy = true },

      { 'j-hui/fidget.nvim', opts = {} }, -- Useful status updates for LSP.
      {
        'ray-x/lsp_signature.nvim',
        lazy = C.opt.performance,
        event = 'VeryLazy',
        opts = {},
        config = function(_, opts)
          opts = vim.tbl_deep_extend('force', opts or {}, {
            floating_window = false,
            hint_enable = true,
            hint_prefix = '',
          })

          require('lsp_signature').setup(opts)
        end,
      },
    },

    config = function()
      --  This function gets run when an LSP attaches to a particular buffer.
      --    That is to say, every time a new file is opened that is associated with
      --    an lsp (for example, opening `main.rs` is associated with `rust_analyzer`) this
      --    function will be executed to configure the current buffer
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
            local go = next and vim.diagnostic.goto_next or vim.diagnostic.goto_prev
            severity = severity and vim.diagnostic.severity[severity] or nil
            return function()
              go { severity = severity }
            end
          end

          lsp_map('n', '<leader>e', vim.diagnostic.open_float, 'Line Diagnostics')
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
          -- lsp_map('n', 'gI', require('telescope.builtin').lsp_implementations, '[G]oto [I]mplementation')

          -- default vim gO
          lsp_map('n', '<leader>ss', require('telescope.builtin').lsp_document_symbols, '[D]ocument [S]ymbols')
          lsp_map('n', '<leader>sS', require('telescope.builtin').lsp_dynamic_workspace_symbols, '[W]orkspace [S]ymbols')
          -- lsp_map('n', '<leader>rn', vim.lsp.buf.rename, '[R]e[n]ame') -- not needed, default nvim keymap is grn
          -- lsp_map('n', '<leader>ca', vim.lsp.buf.code_action, '[C]ode [A]ction') -- not needed, default nvim keymap is gra
          -- lsp_map('v', '<leader>ca', vim.lsp.buf.code_action, 'LSP: [C]ode [A]ction')
          lsp_map('n', 'K', vim.lsp.buf.hover, 'Hover Documentation')
          lsp_map('n', 'gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')
          lsp_map('n', 'gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')

          -- not needed, default nvim keymap is <C-s>
          -- lsp_map('i', '<C-i>', function() -- <Tab> keymapping
          --   vim.lsp.buf.signature_help()
          -- end, 'show signature help')

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

      -- LSP servers and clients are able to communicate to each other what features they support.
      --  By default, Neovim doesn't support everything that is in the LSP Specification.
      --  When you add nvim-cmp, luasnip, etc. Neovim now has *more* capabilities.
      --  So, we create new capabilities with nvim cmp, and then broadcast that to the servers.
      local capabilities = vim.lsp.protocol.make_client_capabilities()
      capabilities = vim.tbl_deep_extend('force', capabilities, require('cmp_nvim_lsp').default_capabilities())

      -- Enable the following language servers
      --  Feel free to add/remove any LSPs that you want here. They will automatically be installed.
      --
      --  Add any additional override configuration in the following tables. Available keys are:
      --  - cmd (table): Override the default command used to start the server
      --  - filetypes (table): Override the default list of associated filetypes for the server
      --  - capabilities (table): Override fields in capabilities. Can be used to disable certain LSP features.
      --  - settings (table): Override the default settings passed when initializing the server.
      --        For example, to see the options for `lua_ls`, you could go to: https://luals.github.io/wiki/settings/
      -- require('mason').setup()

      --- these servers should be ignored by mason-lspconfig
      local is_next = C.cwd.is_next()
      local is_deno = not is_next and C.cwd.is_deno()
      local is_tailwind = C.cwd.is_tailwind()

      local disable = {
        zk = true,
        denols = not is_deno,
        ts_ls = is_deno,
        tailwindcss = not is_tailwind,
      }

      local servers = getServerConfigs()

      vim.diagnostic.config {
        virtual_text = {
          prefix = '■ ', -- Could be '●', '▎', 'x', '■', , 
          -- current_line = true,
        },
        ---@diagnostic disable-next-line: assign-type-mismatch
        float = { border = 'rounded' },
      }

      require('mason-lspconfig').setup {
        automatic_installation = true,
        ensure_installed = {}, -- handled in mason.lua
        handlers = {
          function(server_name)
            local server = servers[server_name] or {}
            -- This handles overriding only values explicitly passed
            -- certain features of an LSP (for example, turning off formatting for tsserver)
            -- by the server configuration above. Useful when disabling

            if not disable[server_name] then
              server.capabilities = vim.tbl_deep_extend('force', {}, capabilities, server.capabilities or {})
              require('lspconfig')[server_name].setup(server)
            end
          end,
        },
      }
    end,
  },
}
