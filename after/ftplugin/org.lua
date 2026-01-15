vim.api.nvim_buf_set_keymap(
  0,
  'n',
  'gd',
  ':lua require("orgmode").action("org_mappings.open_at_point")<CR>',
  { desc = 'org: go to definition (go to heading)' }
)

vim.api.nvim_create_autocmd('ModeChanged', {
  desc = 'org: toggle indent on visual mode',
  callback = function(ev)
    if ev.match:find('v') or ev.match:find('') then
      Org.indent_mode()
    end
  end,
  group = vim.api.nvim_create_augroup('celso-orgmode-autocmd', { clear = true }),
})
