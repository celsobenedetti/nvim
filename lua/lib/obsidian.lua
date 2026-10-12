--- Resolve Obsidian [[wikilinks]] from buffers obsidian.nvim does not own.
--- It only auto-attaches to markdown/quarto buffers inside a vault and resolves
--- links against the *active* workspace; org files sit outside both vaults, so
--- the vault has to be picked per buffer and passed to the resolver. Link
--- parsing itself is plain-text, not markdown-specific, so it works anywhere.
---
---@class LibObsidian
local M = {}

---@param path string
---@param dir string
---@return boolean whether `path` is `dir` itself or lives under it
local function under(path, dir)
  return dir ~= '' and (path == dir or path:sub(1, #dir + 1) == dir .. '/')
end

--- Vault backing `path`: the work vault for the work org files (work.org and
--- its archive) and for notes already inside it, the garden for everything else.
---@param path string? defaults to the current buffer
---@return string vault root, '' when unconfigured
M.vault = function(path)
  path = path or vim.fn.expand('%:p')
  local work = config.dirs.work_notes
  if under(path, work) or (config.org.work ~= '' and path:find(config.org.work, 1, true) == 1) then
    return work
  end
  return config.dirs.garden
end

--- Absolute path of the note the [[wikilink]] under the cursor points at.
---@param fname string? returned when there is no wikilink, so this doubles as an 'includeexpr'
---@return string?
M.wikilink_path = function(fname)
  local vault = M.vault()
  local ok, api = pcall(require, 'obsidian.api')
  if vault == '' or not ok or not Obsidian then
    return fname
  end
  -- cursor_link() only matches when the cursor sits on a [[wikilink]]/[md](link).
  local _, _, _, ref = api.cursor_link()
  if not ref or ref.kind ~= 'wiki' or ref.target == '' then
    return fname
  end
  local found, notes = pcall(require('obsidian.search').resolve_note, ref.target, { dir = vault })
  if not found or not notes[1] then
    return fname
  end
  return tostring(notes[1].path)
end

return M
