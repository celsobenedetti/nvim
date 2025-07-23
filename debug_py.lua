#!/usr/bin/env -S nvim -l
-- vim: ft=lua

-- We use the "luv" Lua bindings that vim includes to spawn the debugpy process
-- In older versions this was exposed as `vim.loop`, in newer version it is `vim.uv`
local uv = vim.uv or vim.loop

local opts = {
  -- `uv.spawn` lets us inherit fds if we provide them as integer here
  -- 0, 1, 2 are stdin, stdout, stderr
  -- This is done to ensure you see the output of the script you're debugging when using `debugpy-run`
  stdio = { 0, 1, 2 },
  detached = true,

  -- lua sets a global `arg` variable to the arguments of the script you run
  args = { "--listen", "localhost:1234", "--wait-for-client", arg[1] },
}

local handle, piderr
local function on_exit(code)
  print("exit " .. code)
  handle:close()
  handle = nil
end

handle, piderr = uv.spawn("debugpy", opts, on_exit)
if not handle then
  print(piderr)
  return
end

-- We get the path to the socket
local parent = assert(os.getenv("NVIM"), "debugpy-run only works if $NVIM is set")

-- And connect to it
local conn = vim.fn.sockconnect("pipe", parent, { rpc = true })

-- And start a new debug session via `dap.run()`
vim.fn.rpcrequest(conn, "nvim_exec_lua", [[require("dap").run(...)]], {
  {
    name = "debugpy-run", -- An arbitrary name

    -- This refers to the dap.adapters.debugpy definition created by nvim-dap-python
    type = "debugpy",

    -- This tells nvim-dap to connect to the debugpy instance listening on 1234
    -- See:
    -- - https://github.com/microsoft/debugpy/wiki/Command-Line-Reference
    -- - https://github.com/microsoft/debugpy/wiki/Debug-configuration-settings
    request = "attach",
    connect = {
      host = "127.0.0.1",
      port = 1234,
    },
    purpose = { "debug-in-terminal" },
    pythonArgs = { "-Xfrozen_modules=off" },
  },
})

-- And block until the debugpy process stop
while handle do
  vim.wait(100, function()
    return false
  end)
end
