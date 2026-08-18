if not lib.cwd.matches({ 'work/io' }) then
  return
end

vim.api.nvim_create_user_command('IoCrawlers', function()
  lib.overseer.run_tasks({
    { name = 'crawler-diff',        cmd = 'npm', args = { 'run', 'devms', 'crawler-diff' } },
    { name = 'wforge-qans-indexer', cmd = 'npm', args = { 'run', 'devms', 'wforge-qans-indexer' } },
    { name = 'wforge-orchestrator', cmd = 'npm', args = { 'run', 'devms', 'wforge-orchestrator' } },
    { name = 'bot-clearer',         cmd = 'npm', args = { 'run', 'devms', 'bot-clearer' } },
  })
end, { desc = 'Run all crawler tasks' })

vim.api.nvim_create_user_command('IoTest', function()
  lib.overseer.run_tasks({
    { name = 'tsc',          cmd = 'pnpm', args = { 'exec', 'tsc' } },
    { name = 'test',         cmd = 'pnpm', args = { 'test' } },
    { name = 'lint:changed', cmd = 'pnpm', args = { 'run', 'lint:changed' } },
    { name = 'fallow:audit', cmd = 'pnpm', args = { 'run', 'fallow:audit' } },
  })
end, { desc = 'Run all crawler tasks' })

vim.api.nvim_create_user_command('IoServers', function()
  lib.overseer.run_tasks({
    { name = 'tsc',       cmd = 'tsc',  args = { '-w' } },
    { name = 'rspack',    cmd = 'pnpm', args = { 'run', 'rspack' } },
    { name = 'devserver', cmd = 'pnpm', args = { 'run', 'devserver' } },
  })
end, { desc = 'Run all crawler tasks' })
