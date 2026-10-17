-- Let gf resolve [[wikilinks]] (see lib.obsidian) and attach the in-process
-- obsidian-ls LSP so blink can offer [[ completion. The LSP completion path is
-- line-text based, not markdown-specific.
if config.dirs.notes ~= '' and vim.fn.expand('%:p'):find(config.dirs.notes, 1, true) == 1 then
  vim.b.obsidian_buffer = true
  -- 'includeexpr' is how gf (and [f, [i, ...) turn the text under the cursor
  -- into a filename: without it gf would look for a file literally named
  -- "[[some note]]", with it the link resolves to the note inside the vault.
  vim.bo.includeexpr = 'v:lua.lib.obsidian.wikilink_path(v:fname)'
  pcall(function()
    require('obsidian.lsp').start(vim.api.nvim_get_current_buf())
  end)
end

-- gd: follow a [[wikilink]] to its markdown note, else orgmode go-to-definition.
vim.keymap.set('n', 'gd', function()
  local path = lib.obsidian.wikilink_path()
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

vim.keymap.set(
  'n',
  '<leader>n',
  lib.org.add_note_or_search_next,
  { buffer = true, desc = 'org: add note (next search match while hlsearch)' }
)
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

-- Reading mode: 'concealcursor' controls whether conceal applies on the cursor
-- line. Empty (default) reveals org_hide_emphasis_markers there; 'nvic' keeps
-- =/~/... hidden under the cursor too. Mirrors <leader>mr in markdown, where
-- render-markdown's anti_conceal pins the same window option.
vim.keymap.set('n', '<leader>rm', function()
  local on = vim.wo.concealcursor == ''
  vim.wo.concealcursor = on and 'nvic' or ''
  vim.notify('org reading mode: ' .. (on and 'on' or 'off'))
end, { buffer = true, desc = 'org: toggle reading mode' })

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

if vim.fn.expand('%:t'):find('org-capture', 1, true) then
  vim.cmd('startinsert')
end
