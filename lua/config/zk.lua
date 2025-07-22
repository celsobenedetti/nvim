local M = {
  NOTES = os.getenv("NOTES") or "",
  INBOX = os.getenv("INBOX") or "",
  PROJECTS = os.getenv("PROJECTS") or "",
  AREAS = os.getenv("AREAS") or "",
  RESOURCES = os.getenv("RESOURCES") or "",
  ARCHIVES = os.getenv("ARCHIVES") or "",
  DAILY = os.getenv("DAILY") or "",
  ORGFILES = os.getenv("ORGFILES") or "",

  -- set below
  ORG_REFILE = "",
  ORG_INDEX = "",
  ORG_WORK = "",

  AI_RULES = os.getenv("AI_RULES") or "",
}

M.ORG_REFILE = M.INBOX .. "/refile.org"
M.ORG_INDEX = M.ORGFILES .. "/i.org"
M.ORG_WORK = M.AREAS .. "/work/work.org"

for k, v in pairs(M) do
  if M[k] == "" then
    print("validation: enviroment variable " .. k .. " not set")
  end
  vim.env[k] = v
end

return M
