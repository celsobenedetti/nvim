-- gd: follow a [[wikilink]] in an agenda line to its note, else orgmode's link
-- at point. The agenda buffer has no file of its own, so the vault is decided
-- by the org file the headline under the cursor comes from.
vim.keymap.set('n', 'gd', function()
  local target = lib.obsidian.wikilink_target()
  local ok, agenda = pcall(require, 'orgmode.api.agenda')
  local headline = ok and agenda.get_headline_at_cursor() or nil
  if not target or not headline then
    require('orgmode').action('agenda.open_at_point')
    return
  end

  local path = lib.obsidian.note_path(target, lib.obsidian.vault(headline.file.filename))
  if not path then
    vim.notify(('No note found for [[%s]]'):format(target), vim.log.levels.WARN)
    return
  end

  -- The agenda usually sits at the bottom of a horizontal split: open the note
  -- above it, splitting only when the agenda is the topmost window.
  vim.cmd.wincmd('k')
  if vim.bo.filetype == 'orgagenda' then
    vim.cmd('aboveleft split')
  end
  vim.cmd.edit(path)
end, { buffer = true, desc = 'agenda: follow [[wikilink]] / open link at point' })

vim.api.nvim_buf_set_keymap(
  0,
  'n',
  'n',
  ':lua require("orgmode").action("org_mappings.agenda.add_note")<CR>',
  { desc = 'org: add note' }
)
