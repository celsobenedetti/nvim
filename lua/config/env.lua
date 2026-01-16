local M = {
  WORK = os.getenv('WORK') or '',
  work = {
    jira = os.getenv('WORK_JIRA') or '',
  },

  HOME = os.getenv('HOME') or '',

  notes = {
    NOTES = os.getenv('NOTES') or '',
    ZK = os.getenv('ZK') or '',
    INBOX = os.getenv('INBOX') or '',
    ORG = os.getenv('ORG') or '',
    PROJECTS = os.getenv('PROJECTS') or '',
    RESOURCES = os.getenv('RESOURCES') or '',
    ARCHIVES = os.getenv('ARCHIVES') or '',
    ASSETS = os.getenv('ASSETS') or '',
    ATTACHMENTS = os.getenv('ATTACHMENTS') or '',

    ORG_REFILE = os.getenv('ORG_REFILE') or '',
    ORG_WORK = os.getenv('ORG_WORK') or '',
    ORG_PURCHASES = os.getenv('ORG_PURCHASES') or '',

    AI_RULES = os.getenv('AI_RULES') or '',
  },
}

M.notes.ASSETS = M.notes.ASSETS:gsub(M.notes.NOTES .. '/', '')

for k, v in pairs(M.notes) do
  if M.notes[k] == '' then
    print('validation: enviroment variable ' .. k .. ' not set')
  end
  vim.env[k] = v
end

return M
