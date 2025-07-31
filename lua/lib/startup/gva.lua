local term = require("lib.term")

---@type term.TabTerm[]
local commands = {
  { title = "tsc", cmd = "tsc -w" },
  { title = "rspack", cmd = "npm run rspack" },
  { title = "devserver", cmd = "pnpm run devserver" },
}

for _, v in ipairs(commands) do
  term.spawn_term(v)
end
