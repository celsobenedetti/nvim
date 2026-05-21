if not require('lib.cwd').matches({ 'work/io' }) then
  return
end

vim.api.nvim_create_user_command('IoCrawlers', function()
  require('lib.overseer.run_tasks').run({
    { name = 'crawler-diff', cmd = 'npm', args = { 'run', 'devms', 'crawler-diff' } },
    { name = 'wforge-qans-indexer', cmd = 'npm', args = { 'run', 'devms', 'wforge-qans-indexer' } },
    { name = 'wforge-orchestrator', cmd = 'npm', args = { 'run', 'devms', 'wforge-orchestrator' } },
    { name = 'bot-clearer', cmd = 'npm', args = { 'run', 'devms', 'bot-clearer' } },
  })
end, { desc = 'Run all crawler tasks' })
