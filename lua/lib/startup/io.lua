---@module startup starts the io servers with overseer

require('lib.overseer.run_tasks').startup {
  { name = 'tsc', cmd = 'tsc', args = { '-w' } },
  { name = 'rspack', cmd = 'pnpm', args = { 'run', 'rspack' } },
  -- { name = 'ms', cmd = 'npm', args = { 'run', 'ms', 'integrations' } },
  { name = 'dev:debug', cmd = 'pnpm', args = { 'run', 'devserver:debug' } },
}
