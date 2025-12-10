local function setup_typescript()
  local dap = require 'dap'

  for _, adapterType in ipairs { 'node', 'chrome', 'msedge' } do
    local pwaType = 'pwa-' .. adapterType

    if not dap.adapters[pwaType] then
      dap.adapters[pwaType] = {
        type = 'server',
        host = 'localhost',
        port = '${port}',
        executable = {
          command = 'js-debug-adapter',
          args = { '${port}' },
        },
      }
    end

    -- Define adapters without the "pwa-" prefix for VSCode compatibility
    if not dap.adapters[adapterType] then
      dap.adapters[adapterType] = function(cb, config)
        local nativeAdapter = dap.adapters[pwaType]

        config.type = pwaType

        if type(nativeAdapter) == 'function' then
          nativeAdapter(cb, config)
        else
          cb(nativeAdapter)
        end
      end
    end
  end

  local js_filetypes = { 'typescript', 'javascript', 'typescriptreact', 'javascriptreact' }

  local vscode = require 'dap.ext.vscode'
  vscode.type_to_filetypes['node'] = js_filetypes
  vscode.type_to_filetypes['pwa-node'] = js_filetypes

  for _, language in ipairs(js_filetypes) do
    if not dap.configurations[language] then
      local runtimeExecutable = nil
      if language:find 'typescript' then
        runtimeExecutable = vim.fn.executable 'tsx' == 1 and 'tsx' or 'ts-node'
      end
      dap.configurations[language] = {
        {
          type = 'pwa-node',
          request = 'launch',
          name = 'Launch file',
          program = '${file}',
          cwd = '${workspaceFolder}',
          sourceMaps = true,
          runtimeExecutable = runtimeExecutable,
          skipFiles = {
            '<node_internals>/**',
            'node_modules/**',
          },
          resolveSourceMapLocations = {
            '${workspaceFolder}/**',
            '!**/node_modules/**',
          },
        },
        {
          type = 'pwa-node',
          request = 'attach',
          name = 'Attach',
          processId = require('dap.utils').pick_process,
          cwd = '${workspaceFolder}',
          sourceMaps = true,
          runtimeExecutable = runtimeExecutable,
          skipFiles = {
            '<node_internals>/**',
            'node_modules/**',
          },
          resolveSourceMapLocations = {
            '${workspaceFolder}/**',
            '!**/node_modules/**',
          },
        },
      }
    end
  end
end
--
--
-- return {
--   {
--     'mfussenegger/nvim-dap',
--     keys = {
--       {
--         '<leader>bC',
--         function()
--           require('dap').clear_breakpoints()
--           Snacks.notify.info 'DAP breakpoints cleared'
--         end,
--         desc = 'DAP: Clear Breakpoints',
--       },
--       {
--         '<leader>bL',
--         function()
--           require('dap').list_breakpoints(true)
--         end,
--         desc = 'DAP List Breakpoints',
--       },
--       {
--         '<leader>do',
--         function()
--           require('dap').step_over()
--         end,
--         desc = 'DAP: Step Over',
--       },
--       {
--         '<leader>dO',
--         function()
--           require('dap').step_out()
--         end,
--         desc = 'DAP: Step Out',
--       },
--       -- TODO: figure out how to use this
--       {
--         '<leader>dl',
--         function()
--           require('osv').launch { port = 8086 }
--         end,
--         desc = 'DAP: One step for vimkind launch',
--       },
--       { '<leader>ds', false },
--
--       {
--         '<F5>',
--         function()
--           require('dap').continue()
--         end,
--         desc = 'Run/Continue',
--       },
--     },
--   },
--
--   {
--     'rcarriga/nvim-dap-ui',
--
--     opts = {
--       layouts = {
--         {
--           -- You can change the order of elements in the sidebar
--           elements = {
--             -- Provide IDs as strings or tables with "id" and "size" keys
--             { id = 'scopes', size = 0.25 },
--             { id = 'breakpoints', size = 0.25 },
--             { id = 'stacks', size = 0.25 },
--             { id = 'repl', size = 0.25 },
--             { id = 'watches', size = 0.25 },
--           },
--           size = 40,
--           position = 'left', -- Can be "left" or "right"
--         },
--         -- {
--         --   elements = {
--         --     'repl',
--         --     'console',
--         --   },
--         --   size = 10,
--         --   position = 'bottom', -- Can be "bottom" or "top"
--         -- },
--       },
--     },
--   },
-- }
--

---@param config {type?:string, args?:string[]|fun():string[]?}
local function get_args(config)
  local args = type(config.args) == 'function' and (config.args() or {}) or config.args or {} --[[@as string[] | string ]]
  local args_str = type(args) == 'table' and table.concat(args, ' ') or args --[[@as string]]

  config = vim.deepcopy(config)
  ---@cast args string[]
  config.args = function()
    local new_args = vim.fn.expand(vim.fn.input('Run with args: ', args_str)) --[[@as string]]
    if config.type and config.type == 'java' then
      ---@diagnostic disable-next-line: return-type-mismatch
      return new_args
    end
    return require('dap.utils').splitstr(new_args)
  end
  return config
end

return {
  {
    'mfussenegger/nvim-dap',
    recommended = true,
    desc = 'Debugging support. Requires language specific adapters to be configured. (see lang extras)',
    dependencies = {
      { 'theHamsta/nvim-dap-virtual-text', opts = {} },
    },
    -- stylua: ignore start
    keys = {
      { "<F5>", function() require("dap").continue() end, desc = "Run/Continue" },
      { "<F9>", function() require("dap").toggle_breakpoint() end, desc = "Toggle Breakpoint" },
      { "<F10>", function() require("dap").step_over() end, desc = "Step Over" },
      { "<F22>", function() require("dap").step_out() end, desc = "Step Out" }, -- shift-f10

      { "<leader>dB", function() require("dap").set_breakpoint(vim.fn.input('Breakpoint condition: ')) end, desc = "Breakpoint Condition" },
      { "<leader>db", function() require("dap").toggle_breakpoint() end, desc = "Toggle Breakpoint" },
      { "<leader>dc", function() require("dap").continue() end, desc = "Run/Continue" },
      { "<leader>da", function() require("dap").continue({ before = get_args }) end, desc = "Run with Args" },
      { "<leader>dC", function() require("dap").run_to_cursor() end, desc = "Run to Cursor" },
      { "<leader>dg", function() require("dap").goto_() end, desc = "Go to Line (No Execute)" },
      { "<leader>di", function() require("dap").step_into() end, desc = "Step Into" },
      { "<leader>dj", function() require("dap").down() end, desc = "Down" },
      { "<leader>dk", function() require("dap").up() end, desc = "Up" },
      { "<leader>dl", function() require("dap").run_last() end, desc = "Run Last" },
      { "<leader>dO", function() require("dap").step_out() end, desc = "Step Out" },
      { "<leader>do", function() require("dap").step_over() end, desc = "Step Over" },
      { "<leader>dP", function() require("dap").pause() end, desc = "Pause" },
      { "<leader>dr", function() require("dap").repl.toggle() end, desc = "Toggle REPL" },
      { "<leader>ds", function() require("dap").session() end, desc = "Session" },
      { "<leader>dt", function() require("dap").terminate() end, desc = "Terminate" },
      { "<leader>dw", function() require("dap.ui.widgets").hover() end, desc = "Widgets" },
      { '<leader>bC', function() require('dap').clear_breakpoints(); Snacks.notify.info 'DAP breakpoints cleared' end, desc = 'DAP: Clear Breakpoints', },
    },
    -- stylua: ignore end

    config = function()
      -- vim.api.nvim_set_hl(0, 'DapStoppedLine', { default = true, link = 'Visual' })
      -- setup dap config by VsCode launch.json file
      local vscode = require 'dap.ext.vscode'
      local json = require 'plenary.json'
      vscode.json_decode = function(str)
        return vim.json.decode(json.json_strip_comments(str))
      end

      setup_typescript()
    end,
  },

  {
    'igorlfs/nvim-dap-view',
    cmd = { 'DapViewOpen', 'DapViewToggle' },
    ---@module 'dap-view'
    ---@type dapview.Config
    opts = {},
    keys = { { '<leader>du', ':DapViewToggle<CR>', desc = 'DAP: UI toggle' } },
  },

  -- mason.nvim integration
  {
    'jay-babu/mason-nvim-dap.nvim',
    dependencies = 'mason.nvim',
    cmd = { 'DapInstall', 'DapUninstall' },
    opts = {
      -- Makes a best effort to setup the various debuggers with
      -- reasonable debug configurations
      automatic_installation = true,

      -- You can provide additional configuration to the handlers,
      -- see mason-nvim-dap README for more information
      handlers = {},

      -- You'll need to check that you have the required things installed
      -- online, please don't ask me how to install them :)
      ensure_installed = {
        -- Update this to ensure that you have the debuggers for the langs you want
      },
    },
    -- mason-nvim-dap is loaded when nvim-dap loads
    config = function() end,
  },
}
