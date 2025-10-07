-- https://github.com/stevearc/overseer.nvim/blob/master/doc/guides.md#L56-L56

local M = {}

M.test = {
  name = 'act -j test',
  builder = function(params)
    return {
      cmd = { 'act' },
      args = { '-j', 'test' },
      name = 'act -j test',
      cwd = vim.g.dirs.work.edge_server,
      components = { 'default' },
    }
  end,
  desc = 'run CI tests with act',
  condition = {
    dir = vim.g.dirs.work.edge_server,
  },
}

M.lint = {
  name = 'act -j lint',
  builder = function(params)
    return {
      cmd = { 'act' },
      args = { '-j', 'lint' },
      name = 'act -j lint',
      cwd = vim.g.dirs.work.edge_server,
      components = { 'default' },
    }
  end,
  desc = 'run CI tests with act',
  condition = {
    dir = vim.g.dirs.work.edge_server,
  },
}

return M
