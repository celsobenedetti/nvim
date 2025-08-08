local M = {
  NOTES = os.getenv 'NOTES' or '',
  INBOX = os.getenv 'INBOX' or '',
  PROJECTS = os.getenv 'PROJECTS' or '',
  AREAS = os.getenv 'AREAS' or '',
  RESOURCES = os.getenv 'RESOURCES' or '',
  ARCHIVES = os.getenv 'ARCHIVES' or '',
  DAILY = os.getenv 'DAILY' or '',

  ORG_INDEX = os.getenv 'ORG_INDEX' or '',
  ORG_REFILE = os.getenv 'ORG_REFILE' or '',
  ORG_WORK = os.getenv 'ORG_WORK' or '',

  -- AI_RULES = os.getenv 'AI_RULES' or '',
}

for k, v in pairs(M) do
  if M[k] == '' then
    print('validation: enviroment variable ' .. k .. ' not set')
  end
  vim.env[k] = v
end

return M
