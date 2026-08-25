-- use rg for native grep
-- and custom Grep command to grep and qflist
-- Base flags first, config.cmd.rg.ignore appended last so its args win any
-- conflicts (its --no-ignore cancels gitignore respect, its -g !globs exclude).
-- Same arg set as the <C-S-g> fzf grep in after/plugin/keymaps.lua.
--
-- `-e $*`: :grep appends pattern+files here; -e keeps patterns starting with
-- `-` from being parsed as flags.
local prg = vim.list_extend({ 'rg', '--vimgrep', '--smart-case', '--hidden' }, config.cmd.rg.ignore)
vim.opt.grepprg = table.concat(prg, ' ') .. ' -e $*'
vim.opt.grepformat = '%f:%l:%c:%m'

local function do_grep(pattern, target)
  local cmd = 'silent grep ' .. vim.fn.fnameescape(pattern)
  if target then
    -- expand cmdline-special chars (% = current file, # = alternate, ~, <cword>, ...)
    -- so `:Grep query %` greps the current file. Only the target is expanded:
    -- expanding the pattern would mangle regex escapes (expandcmd('\b') -> <BS>).
    cmd = cmd .. ' ' .. vim.fn.fnameescape(vim.fn.expandcmd(target))
  end
  vim.cmd(cmd)
  vim.cmd.copen()
end

-- Drop noise lines (config.cmd.rg.exclude_lines) from grep results — the
-- equivalent of the `-v <pat>` args the fzf keymap passes rg. Runs on
-- QuickFixCmdPost so it applies to plain :grep too.
vim.api.nvim_create_autocmd('QuickFixCmdPost', {
  group = vim.api.nvim_create_augroup('grep:filter-excluded-lines', { clear = true }),
  callback = function(ev)
    if ev.match ~= 'grep' or #config.cmd.rg.exclude_lines == 0 then
      return
    end
    local items = vim.fn.getqflist()
    local kept = {}
    for _, item in ipairs(items) do
      local excluded = false
      for _, pat in ipairs(config.cmd.rg.exclude_lines) do
        if item.text and item.text:find(pat, 1, true) then
          excluded = true
          break
        end
      end
      if not excluded then
        kept[#kept + 1] = item
      end
    end
    vim.fn.setqflist(kept, 'r')
  end,
})

vim.api.nvim_create_user_command('Grep', function(opts)
  -- Split args into tokens on whitespace, honoring "..." and '...' quoting and
  -- backslash escapes (space, quote, backslash). Regex backslashes like `\b` are
  -- kept verbatim. This lets `:Grep "some query" file.txt` parse the quoted
  -- pattern as a single token, unlike a dumb split on spaces.
  local args = lib.strings.split_args(opts.args)
  if #args == 0 then
    vim.ui.input({ prompt = 'Grep: ' }, function(input)
      if input and input ~= '' then
        do_grep(input)
      end
    end)
    return
  end
  if #args > 2 then
    vim.notify('Usage: :Grep [pattern] [target]', vim.log.levels.WARN)
    return
  end
  if args[1] == '' then
    vim.notify('Grep: empty pattern', vim.log.levels.WARN)
    return
  end
  do_grep(args[1], args[2])
end, { nargs = '*', desc = 'rg grep; optional second arg scopes to a file or dir' })
