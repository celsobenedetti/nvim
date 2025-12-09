local M = {
  work = {
    edge_server = (os.getenv 'WORK' or '') .. '/integrations-private',
  },
}

return M
