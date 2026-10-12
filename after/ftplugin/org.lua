-- Follow Obsidian-style [[wikilinks]] from org files into the markdown vaults.
-- obsidian.nvim only auto-attaches to markdown/quarto buffers and resolves links
-- against the *active* workspace; org files sit outside both vaults, so we pick
-- the vault ourselves and pass it to the resolver. Link parsing is plain-text,
-- not markdown-specific, so it works in an org buffer.

-- work.org links into the work vault, every other org file into the garden.
local function obsidian_vault()
  if config.org.work ~= '' and vim.fn.expand('%:p') == config.org.work then
    return config.dirs.work_notes
  end
  return config.dirs.garden
end

--- Absolute path of the note the [[wikilink]] under the cursor points at.
---@param fname string|nil fallback for includeexpr when there is no wikilink
---@return string|nil
function _G.org_wikilink_path(fname)
  local vault = obsidian_vault()
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

-- Let gf resolve [[wikilinks]] through the same vault, and attach the in-process
-- obsidian-ls LSP so blink can offer [[ completion. The LSP completion path is
-- line-text based, not markdown-specific.
if config.dirs.notes ~= '' and vim.fn.expand('%:p'):find(config.dirs.notes, 1, true) == 1 then
  vim.b.obsidian_buffer = true
  vim.bo.includeexpr = 'v:lua.org_wikilink_path(v:fname)'
  pcall(function()
    require('obsidian.lsp').start(vim.api.nvim_get_current_buf())
  end)
end

-- gd: follow a [[wikilink]] to its markdown note, else orgmode go-to-definition.
vim.keymap.set('n', 'gd', function()
  local path = _G.org_wikilink_path()
  if path then
    vim.cmd.edit(path)
    return
  end
  require('orgmode').action('org_mappings.open_at_point')
end, { buffer = true, desc = 'org: follow [[wikilink]] / go to definition' })

vim.api.nvim_buf_set_keymap(
  0,
  'n',
  '<leader>j',
  '<Cmd>lua require("orgmode").action("org_mappings.insert_heading_respect_content")<CR>',
  { desc = 'org: insert headline (respect content)' }
)
vim.api.nvim_buf_set_keymap(
  0,
  'n',
  't',
  ':lua require("orgmode").action("org_mappings.todo_next_state")<CR>',
  { desc = 'org: change todo state' }
)

_G.org_n = _G.org_n
  or function()
    if vim.v.hlsearch == 1 then
      vim.cmd('normal! n')
      return
    end
    require('orgmode').action('org_mappings.add_note')
  end

vim.api.nvim_buf_set_keymap(0, 'n', '<leader>n', ':lua _G.org_n()<CR>', { desc = 'org: add note' })
vim.api.nvim_buf_set_keymap(
  0,
  'n',
  'X',
  ':lua require("orgmode").action("clock.org_clock_cancel")<CR>',
  { desc = 'org: cancel clock' }
)

vim.keymap.set('n', 'R', function()
  lib.org_fzf.refile_heading()
end, { desc = 'org: refile headline', buf = 0 })

vim.api.nvim_create_autocmd('ModeChanged', {
  desc = 'org: toggle indent on visual mode',
  callback = function(ev)
    if ev.match:find('v') or ev.match:find('') then
      Org.indent_mode()
    end
  end,
  group = vim.api.nvim_create_augroup('celso-orgmode-autocmd', { clear = true }),
})

-- diosable comment continuation on different lines
-- https://neovim.discourse.group/t/how-do-i-prevent-neovim-commenting-out-next-line-after-a-comment-line/3711/7
vim.opt_local.formatoptions:remove({ 'r', 'o' })
