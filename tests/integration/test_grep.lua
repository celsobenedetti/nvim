-- Integration test (real nvim, headless): :Grep passes its pattern to rg
-- intact. `:grep` splices its arguments into 'grepprg' and hands the result
-- straight to the shell (no escaping of its own), so a pattern holding shell
-- metacharacters needs shellescape — `:Grep <leader>pi` used to lose `>pi` to a
-- shell redirect and search for `<leader>` instead.
--
-- Run via `make test-integration` (nvim --headless -u NONE -l).

local cwd = vim.fn.getcwd()
vim.opt.runtimepath:prepend(cwd)

_G.config = { cmd = { rg = { ignore = {}, exclude_lines = {} } } }
_G.lib = { strings = require('lib.strings') }

vim.cmd('luafile ' .. cwd .. '/after/plugin/grep.lua')

-- A fixture of its own so the assertions count exact hits, unaffected by the
-- repo's contents.
local dir = vim.fn.tempname()
vim.fn.mkdir(dir, 'p')
local lines = {
  "{ key = '<leader>pi', cmd = 'pi' },",
  'local alt = vim.opt or vim.o',
  'rm -rf $HOME; echo `id` & true',
  'spaced out (parens) and [brackets]',
  'plain line with no specials',
}
vim.fn.writefile(lines, dir .. '/fixture.lua')
vim.cmd.cd(dir)

--- Run `:Grep args` and return the distinct matched lines (the %m of each qf
--- entry; --vimgrep reports one entry per match, so a line can repeat).
local function grep(args)
  vim.cmd('Grep ' .. args)
  local texts, seen = {}, {}
  for _, item in ipairs(vim.fn.getqflist()) do
    if not seen[item.text] then
      seen[item.text] = true
      texts[#texts + 1] = item.text
    end
  end
  vim.cmd('cclose')
  return texts
end

local cases = {
  -- pattern passed to :Grep        -- fixture line it must match
  { '<leader>pi', lines[1] },
  { "'vim.opt|vim.o'", lines[2] },
  { "'\\$HOME'", lines[3] }, -- `\$` so rg reads a literal `$`, not an end-of-line anchor
  { "'`id`'", lines[3] },
  { "'rf \\$HOME; echo'", lines[3] },
  { "'(parens)'", lines[4] },
  { "'\\[brackets\\]'", lines[4] },
  { '"spaced out"', lines[4] },
}

for _, case in ipairs(cases) do
  local pattern, want = case[1], case[2]
  local got = grep(pattern)
  assert(#got == 1 and got[1] == want, ('`:Grep %s` matched %s, want { %q }'):format(pattern, vim.inspect(got), want))
end
print('PASS: shell metacharacters in the pattern reach rg intact')

-- The target is expanded (`%` = current file) but must survive the shell too,
-- hence a fixture dir named with a space.
local spaced = dir .. '/a b'
vim.fn.mkdir(spaced, 'p')
vim.fn.writefile({ 'needle here' }, spaced .. '/f.txt')
local got = grep("needle 'a b'")
assert(#got == 1 and got[1] == 'needle here', 'target with a space: ' .. vim.inspect(got))

vim.cmd.edit(spaced .. '/f.txt')
got = grep('needle %')
assert(#got == 1 and got[1] == 'needle here', '`%` target expansion: ' .. vim.inspect(got))
print('PASS: target arg expands `%` and survives a space in the path')

vim.cmd.cd(cwd)
vim.fn.delete(dir, 'rf')
