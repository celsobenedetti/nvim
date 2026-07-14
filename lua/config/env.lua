local M = {
  WORK = os.getenv('WORK') or '',
  work = {
    jira = os.getenv('WORK_JIRA') or '',
  },
  JIRA_API_TOKEN = os.getenv('JIRA_API_TOKEN') or '',

  HOME = os.getenv('HOME') or '',
  quartz = 'http://localhost:42069',

  notes = {
    NOTES = os.getenv('NOTES') or '',
    OBSIDIAN_VAULT = os.getenv('OBSIDIAN_VAULT') or '',
    OBSIDIAN_VAULT_PRIVATE = os.getenv('OBSIDIAN_VAULT_PRIVATE') or '',
    OBSIDIAN_INBOX = os.getenv('OBSIDIAN_INBOX') or '',
    ORG = os.getenv('ORG') or '',
    PROJECTS = os.getenv('PROJECTS') or '',
    ARCHIVES = os.getenv('ARCHIVES') or '',

    ASSETS_DIR = os.getenv('ASSETS_DIR') or '',
    ASSETS = os.getenv('ASSETS') or '',
    ATTACHMENTS = os.getenv('ATTACHMENTS') or '',

    GREP_IGNORE = os.getenv('GREP_NOTES_IGNORE') or '',
  },
  org = {
    INBOX = os.getenv('ORG_INBOX') or '',
    MAIN = os.getenv('ORG_MAIN') or '',
    WORK = os.getenv('ORG_WORK') or '',
    REFERENCES = os.getenv('ORG_REFERENCES') or '',
    CALENDAR = os.getenv('ORG_CALENDAR') or '',
    PURCHASES = os.getenv('ORG_PURCHASES') or '/home/celso/notes/0 org/Purchases.org',
  },
}

-- Keep full absolute path; do not strip NOTES prefix
-- M.notes.ASSETS = M.notes.ASSETS:gsub(M.notes.NOTES .. '/', '')

for k, v in pairs(M.notes) do
  if M.notes[k] == '' then
    print('validation: enviroment variable ' .. k .. ' not set')
  end
  vim.env[k] = v
end

return M
