local M = {}

M.pyright = {
  name = 'gh act -j pyright',
  builder = function(params)
    return {
      cmd = { 'act' },
      args = { '-j', 'pyright' },
      name = 'act -j pyright',
      cwd = vim.g.dirs.work.airflow_pipeline,
      components = { 'default' },
    }
  end,
  desc = 'run pyright checks with act',
  condition = {
    dir = vim.g.dirs.work.airflow_pipeline,
  },
}

M.setup = function(overseer)
  overseer.register_template(M.pyright)
end

return M
