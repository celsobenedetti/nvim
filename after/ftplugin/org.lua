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
vim.api.nvim_buf_set_keymap(0, 'n', 're', ':lua require("telescope").extensions.orgmode.refile_heading()<CR>',
  { desc = 'org: refile' }
)

_G.org_n = _G.org_n or function()
  if vim.v.hlsearch == 1 then
    vim.cmd('normal! n')
    return
  end
  require('orgmode').action('org_mappings.add_note')
end

vim.api.nvim_buf_set_keymap(0, 'n', '<leader>n', ':lua _G.org_n()<CR>',
  { desc = 'org: add note' }
)
vim.api.nvim_buf_set_keymap(0, 'n', 'X', ':lua require("orgmode").action("clock.org_clock_cancel")<CR>',
  { desc = 'org: cancel clock' }
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
