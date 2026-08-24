-- Integration test (real nvim, headless): lib.diff_filepath overlays each
-- `diff --git` header line with a winbar-like filepath bar, without touching
-- the buffer text. The extmark namespace is `nvim.*` so nvim-treesitter-context
-- mirrors it into its context window (verified separately against the plugin's
-- render.copy_extmarks; see the module comment in lib/diff_filepath.lua).
--
-- Run via `make test-integration` (nvim --headless -u NONE -l).

vim.opt.rtp:prepend(vim.fn.getcwd())
package.path = vim.fn.getcwd() .. '/lua/?.lua;' .. package.path

local function assert_eq(got, want, msg)
  if vim.inspect(got) ~= vim.inspect(want) then
    error(string.format('%s: got %s, want %s', msg or 'assert', vim.inspect(got), vim.inspect(want)))
  end
end

-- The alias from after/plugin/autocmds.lua, mirrored here (under -u NONE
-- nothing sources the live config).
vim.treesitter.language.register('diff', 'git')

local lines = {
  'diff --git a/foo.txt b/foo.txt',
  'index 1111111..2222222 100644',
  '--- a/foo.txt',
  '+++ b/foo.txt',
  '@@ -1,2 +1,2 @@',
  '-old line',
  '+new line',
  ' context',
  'diff --git a/logo.png b/logo.png',
  'Binary files a/logo.png and b/logo.png differ',
}
local buf = vim.api.nvim_create_buf(false, true)
vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
vim.bo[buf].filetype = 'git'

-- Wait for the parser to become available / parse successfully.
local parsed = false
for _ = 1, 100 do
  local ok = pcall(function()
    return vim.treesitter.get_parser(buf):parse()[1]
  end)
  if ok then
    parsed = true
    break
  end
  vim.wait(50)
end
assert(parsed, 'diff parser parsed buffer')

require('lib.diff_filepath').render(buf)

-- The buffer text must be untouched: the bar is pure extmarks.
assert_eq(vim.api.nvim_buf_get_lines(buf, 0, -1, false), lines, 'buffer text unchanged')

local ns = vim.api.nvim_create_namespace('nvim.diff_filepath')
local marks = vim.api.nvim_buf_get_extmarks(buf, ns, 0, -1, { details = true })

-- No mini.icons under -u NONE, so the icon chunk is absent and paths render
-- bare. Blocks: foo.txt (1 add, 1 del) on row 0; logo.png (binary, no hunks)
-- on row 8.
assert_eq(marks, {
  {
    1,
    0,
    0,
    {
      end_col = 0,
      end_right_gravity = false,
      end_row = 1,
      hl_eol = true,
      hl_group = 'DiffFileBar',
      ns_id = ns,
      priority = 4096,
      right_gravity = true,
      virt_text = {
        { 'foo.txt', 'DiffFileBarPath' },
        { ' +1 -1', 'DiffFileBarSummary' },
      },
      virt_text_hide = false,
      virt_text_pos = 'overlay',
      virt_text_repeat_linebreak = false,
    },
  },
  {
    2,
    8,
    0,
    {
      end_col = 0,
      end_right_gravity = false,
      end_row = 9,
      hl_eol = true,
      hl_group = 'DiffFileBar',
      ns_id = ns,
      priority = 4096,
      right_gravity = true,
      virt_text = { { 'logo.png', 'DiffFileBarPath' } },
      virt_text_hide = false,
      virt_text_pos = 'overlay',
      virt_text_repeat_linebreak = false,
    },
  },
}, 'header bars overlay each block with icon-free path + summary chunks')

print('OK: lib.diff_filepath header bars')
vim.cmd('qa!')
