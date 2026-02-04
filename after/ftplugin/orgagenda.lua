vim.api.nvim_buf_set_keymap(
  0,
  'n',
  'n',
  ':lua require("orgmode").action("org_mappings.agenda.add_note")<CR>',
  { desc = 'org: add note' }
)
