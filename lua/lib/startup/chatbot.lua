---@module startup starts the GVA servers with overseer

require('lib.overseer.run_tasks').startup(
  --- @type task[]
  {
    { name = 'conversation', cmd = 'pnpm', args = { 'dev:debug' }, cwd = 'packages/conversation' },
    { name = 'admin', cmd = 'pnpm', args = { 'dev' }, cwd = 'packages/admin' },
    { name = 'ngrok', cmd = 'ngrok', args = { 'http', '--domain=adfs-test-celso.ngrok.io', '4747' } },
    {
      name = 'drupal_health',
      cmd = 'docker',
      args = {
        'exec',
        '-it',
        'GetAnswers_php',
        'bash',
        '-c',
        ' composer install; drush updb -y; drush cr; drush cim -y; drush core:cron;',
      },
    },
  }
)
