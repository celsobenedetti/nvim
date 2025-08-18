-- https://github.com/stevearc/overseer.nvim/blob/master/doc/guides.md#L56-L56
return {
  name = 'gh act -j test',
  builder = function(params)
    return {
      cmd = { 'gh' },
      args = { 'act', '-j', 'test' },
      name = 'gh act -j test',
      cwd = vim.g.dirs.work.edge_server,
      components = { 'default' },
    }
  end,
  desc = 'run CI tests with gh act',
  condition = {
    dir = vim.g.dirs.work.edge_server,
  },
}
