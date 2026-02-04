-- stylua: ignore start
vim.api.nvim_buf_set_keymap(0, 'n', 'gd', ':lua require("orgmode").action("org_mappings.open_at_point")<CR>',
  { desc = 'org: go to definition (go to heading)' }
)
vim.api.nvim_buf_set_keymap(0, 'n', '<leader>j', '<Cmd>lua require("orgmode").action("org_mappings.insert_heading_respect_content")<CR>',
  { desc = 'org: insert headline (respect content)' }
)
vim.api.nvim_buf_set_keymap(0, 'n', 't', ':lua require("orgmode").action("org_mappings.todo_next_state")<CR>',
  { desc = 'org: change todo state' }
)

vim.api.nvim_buf_set_keymap(0, 'n', 'n', ':lua require("orgmode").action("org_mappings.add_note")<CR>',
  { desc = 'org: add note' }
)
-- stylua: ignore end

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
