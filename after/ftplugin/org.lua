-- Follow Obsidian-style [[wikilinks]] from org files into the markdown vault.
-- obsidian.nvim only auto-attaches to markdown/quarto buffers, but its link
-- resolution is plain-text (not tied to the markdown parser), so we reuse it for
-- org files that live inside a configured workspace. Returns true if it handled
-- a wikilink, false otherwise (so callers can fall back to orgmode).

local function obsidian_follow_wikilink()
  local notes = config.env and config.env.notes
  if not notes or not config.dirs.notes then
    return false
  end
  local filepath = vim.fn.expand('%:p')
  if filepath == '' or filepath:find(config.dirs.notes, 1, true) ~= 1 then
    return false
  end
  local ok, api = pcall(require, 'obsidian.api')
  -- cursor_link() only matches when the cursor sits on a [[wikilink]]/[md](link).
  if not ok or not api.cursor_link() then
    return false
  end
  return pcall(function()
    api.follow_link()
  end)
end

-- Let obsidian.nvim's gf/includeexpr resolve [[wikilinks]] in org buffers, and
-- attach the in-process obsidian-ls LSP so blink can offer [[ completion. The
-- LSP completion path is line-text based, not markdown-specific.
do
  local notes = config.env and config.env.notes
  local filepath = vim.fn.expand('%:p')
  if notes and config.dirs.notes and filepath ~= '' and filepath:find(config.dirs.notes, 1, true) == 1 then
    vim.b.obsidian_buffer = true
    vim.bo.includeexpr = "v:lua.require('obsidian.link').includeexpr(v:fname)"
    pcall(function()
      require('obsidian.lsp').start(vim.api.nvim_get_current_buf())
    end)
  end
end

-- gd: follow a [[wikilink]] to its markdown note, else orgmode go-to-definition.
vim.keymap.set('n', 'gd', function()
  if obsidian_follow_wikilink() then
    return
  end
  require('orgmode').action('org_mappings.open_at_point')
end, { buffer = true, desc = 'org: follow [[wikilink]] / go to definition' })

-- stylua: ignore start
vim.api.nvim_buf_set_keymap(0, 'n', '<leader>j', '<Cmd>lua require("orgmode").action("org_mappings.insert_heading_respect_content")<CR>',
  { desc = 'org: insert headline (respect content)' }
)
vim.api.nvim_buf_set_keymap(0, 'n', 't', ':lua require("orgmode").action("org_mappings.todo_next_state")<CR>',
  { desc = 'org: change todo state' }
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

if not state.capture then
  vim.keymap.set('n', 'R', function()
    require('orgmode').action('capture.refile_headline_to_destination')
  end, { desc = 'org: refile headline' })
end
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
