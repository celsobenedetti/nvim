---@module TypeScript_DAP setup function
return function()
  local dap = require 'dap'
  require('dap').adapters['pwa-node'] = {
    type = 'server',
    host = 'localhost',
    port = '${port}',
    executable = {
      command = 'node',
      args = {
        require('mason-registry').get_package('js-debug-adapter'):get_install_path() .. '/js-debug/src/dapDebugServer.js',
        '${port}',
      },
    },
  }
  for _, language in ipairs { 'typescript', 'javascript', 'typescriptreact', 'javascriptreact' } do
    dap.configurations[language] = {
      {
        type = 'pwa-node',
        request = 'launch',
        name = 'Launch file ',
        program = '${file}',
        cwd = '${workspaceFolder}',
        runtimeExecutable = 'ts-node', -- requires ts-node on $PATH
      },
      {
        type = 'pwa-node',
        request = 'attach',
        name = 'Attach ',
        processId = require('dap.utils').pick_process,
        cwd = '${workspaceFolder}',
        resolveSourceMapLocations = {
          '${workspaceFolder}/**',
          '!**/node_modules/**',
          '!**/.pnpm/**',
        },
      },

      {
        type = 'pwa-node',
        request = 'attach',
        name = 'Attach Nest ',
        port = 7000,
        processId = require('dap.utils').pick_process,
        cwd = '${workspaceFolder}',
        resolveSourceMapLocations = {
          '${workspaceFolder}/**',
          '!**/node_modules/**',
          '!**/.pnpm/**',
        },
      },
    }
  end
end
