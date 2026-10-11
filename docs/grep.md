# `:Grep` target arg and cmdline-special expansion

Findings from fixing `:Grep query %` (commit `5be9a18` "feat(grep): support
target arg" broke it; `288dcdc` fixed it). `:Grep query %` was supposed to grep
the current file but rg got a literal `%` filename:

```
rg: %: IO error for operation on %: No such file or directory os error 2
```

## The root-cause chain (all verified empirically)

1. **Lua user commands pass `opts.args` unexpanded.** `nvim_create_user_command`
   callbacks receive `%`, `#`, `<cword>` etc. as literal text. Built-in commands
   like `:grep` expand them; user-defined commands do not.
2. **`fnameescape('%')` → `\%`.** `fnameescape()` escapes `%` (and `#`, `*`, `?`,
   ...) _anywhere_ in the string, not just at the start: `fnameescape('100%')` →
   `100\%`.
3. **The built-in `:grep` then treats `\%` as an escaped literal `%`** (per
   `:h cmdline-special`, a backslash before a special char makes it literal) and
   passes the filename `%` to rg. A _bare_ `%` would have been expanded by
   `:grep` itself — the escape happened too early.

Fix: expand the target with `vim.fn.expandcmd(target)` **before** fnameescaping.
`expandcmd('%')` → `myfile.txt`, `expandcmd('%:p')` → `/abs/path/myfile.txt`.

## The three functions and when to use each

| Function        | Expands                                                                                                             | Pitfall                                                                                                                                                                                                  |
| --------------- | ------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `expand()`      | one keyword (`%`, `#`, `<cword>`, `$VAR`) + modifiers                                                               | single item, not a whole arg list                                                                                                                                                                        |
| `expandcmd()`   | whole string like an Ex command line: keywords anywhere, `$VAR` anywhere, `~`/`~user` at start, `:p`/`:h` modifiers | **mangles regex backslashes**: `expandcmd('\bfoo')` → `^Hfoo` (0x08)                                                                                                                                     |
| `fnameescape()` | nothing — _escapes_ special filename chars (`%`→`\%`)                                                               | by design **prevents** cmdline-special expansion (`:h cmdline-special` recommends it "to avoid the effects of special characters") — use only after expansion, never before a built-in that would expand |

`expandcmd()` is documented as "especially useful for the argument of a user
defined command" — it is the canonical tool for `opts.args` handling.

`vim.cmd()` / `:execute` perform no expansion of their own; the _invoked
built-in_ expands unescaped specials in the resulting command line.

## `:grep` passes args through the shell

`grepformat`/`grepprg` (`rg --vimgrep ...`) means `:grep` runs the shell:
`!rg --vimgrep -uu <pattern> <files> 2>&1| tee <tmp>`. Consequences:

- **Shell globs work when unescaped**: `:grep hello *.lua` expands `*.lua` in
  the shell. A fnameescaped `\*.lua` is a literal filename → `rg: *.lua: No such
file`. So the target's glob support is limited by the same pre-escaping issue
  `%` had; `expandcmd()` does not glob either.
- Filenames with spaces need escaping: `fnameescape('my file.txt')` →
  `my\ file.txt`, which the shell word-splits correctly.

## `fnameescape` is not a shell escape (`:Grep <leader>pi` found nothing)

The section above understates it: `:grep` does **no** escaping at all.
`make_get_fullcmd()` in `src/nvim/quickfix.c` wraps 'grepprg' (with `$*` already
replaced by `eap->arg`) in 'shellquote' — empty by default — and hands the
string to `do_shell()`. Whatever survives the ex-cmdline parser is shell source.

So `fnameescape(pattern)` was the wrong tool for the pattern: it escapes for the
_cmdline_, and the shell-special chars it leaves alone are exactly the dangerous
ones. `:Grep <leader>pi` became `silent grep \<leader>pi` → cmdline dropped the
`\` → shell read `>pi` as a redirect, so rg searched for `<leader` and wrote its
output to a file named `pi`. Same class of loss for `|`, `;`, `&`, `$`, backticks.

Double-escaping does not work either. `fnameescape(shellescape(p))` backslashes
the quotes, and the cmdline only strips a backslash before `%`, `#` and `<`
(`EX_XFILE` expansion) — the rest reach rg literally.

Fix: skip the cmdline layer with the table form of `vim.cmd`, whose `magic`
field turns off that expansion, and shellescape each arg for the one layer that
is real:

```lua
vim.cmd({
  cmd = 'grep',
  args = { vim.fn.shellescape(pattern) },
  mods = { silent = true },
  magic = { file = false, bar = false },
})
```

`magic.file = false` also means `%`/`#`/`<cword>` in the _pattern_ are no longer
expanded behind our back, which is what we wanted all along — the target still
gets `expandcmd()` applied explicitly first. Regression-tested in
`tests/integration/test_grep.lua`.

Shell globbing in the target stays unavailable — `fnameescape` already broke it
(see above), and shellescape keeps `*.lua` a literal path. Use rg's own `-g` or
a directory target instead.

## Pitfall found while investigating: `split_args` stripped regex escapes (fixed)

The `split_args` tokenizer (introduced in the same commit `5be9a18`) treated
`\X` as escaped-`X` for _any_ X (shell-style), inside quotes too. rg patterns
lost their backslashes: `:Grep \bfoo\b file.txt` searched for `bfoob` instead
of the word-boundary regex.

Fix (`288dcdc` follow-up): a backslash now only escapes a following space,
quote, or backslash — anything else (`\b`, `\d`, `\.`, ...) is kept verbatim.
`\bfoo\b` survives as-is; `foo\ bar` still splits into one token. The function
now lives in `lua/lib/strings.lua` as `M.split_args` (unit-tested in
`tests/lib/test_strings.lua`, run by `make test`).

Note this is a _tokenizer_ rule: the regex escaping question only exists here
because Lua user commands pass `opts.args` raw. A built-in like `:grep` would
hand the whole line to the ex parser, which has its own escape rules.

## Verification

Headless integration tests asserted on `vim.fn.getqflist()` (bufnr/lnum), e.g.
`:Grep target %` → 1 entry pointing at the current file. See AGENTS.md
"Testing" for the headless pitfalls (the `:q`-after-`copen` hang, shell-output
invisibility, `-c` backslash mangling).
