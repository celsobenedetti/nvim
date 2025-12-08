require('lib.overseer.run_tasks').startup {
  { name = 'conversation', cmd = { 'pnpm', 'dev' }, cwd = 'packages/conversation' },
  { name = 'admin', cmd = { 'pnpm', 'dev' }, cwd = 'packages/admin' },
  -- { name = 'ngrok', cmd = 'ngrok', args = { 'http', '--domain=adfs-test-celso.ngrok.io', '4747' } },
  {
    name = 'drupal_health',
    cmd = {
      'docker',
      'exec',
      '-it',
      'GetAnswers_php',
      'bash',
      '-c',
      ' composer install; drush updb -y; drush cr; drush cim -y; drush core:cron;',
    },
  },
}
