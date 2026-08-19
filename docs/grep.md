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
   ...) *anywhere* in the string, not just at the start: `fnameescape('100%')` →
   `100\%`.
3. **The built-in `:grep` then treats `\%` as an escaped literal `%`** (per
   `:h cmdline-special`, a backslash before a special char makes it literal) and
   passes the filename `%` to rg. A *bare* `%` would have been expanded by
   `:grep` itself — the escape happened too early.

Fix: expand the target with `vim.fn.expandcmd(target)` **before** fnameescaping.
`expandcmd('%')` → `myfile.txt`, `expandcmd('%:p')` → `/abs/path/myfile.txt`.

## The three functions and when to use each

| Function | Expands | Pitfall |
|---|---|---|
| `expand()` | one keyword (`%`, `#`, `<cword>`, `$VAR`) + modifiers | single item, not a whole arg list |
| `expandcmd()` | whole string like an Ex command line: keywords anywhere, `$VAR` anywhere, `~`/`~user` at start, `:p`/`:h` modifiers | **mangles regex backslashes**: `expandcmd('\bfoo')` → `^Hfoo` (0x08) |
| `fnameescape()` | nothing — *escapes* special filename chars (`%`→`\%`) | by design **prevents** cmdline-special expansion (`:h cmdline-special` recommends it "to avoid the effects of special characters") — use only after expansion, never before a built-in that would expand |

`expandcmd()` is documented as "especially useful for the argument of a user
defined command" — it is the canonical tool for `opts.args` handling.

`vim.cmd()` / `:execute` perform no expansion of their own; the *invoked
built-in* expands unescaped specials in the resulting command line.

## `:grep` passes args through the shell

`grepformat`/`grepprg` (`rg --vimgrep ...`) means `:grep` runs the shell:
`!rg --vimgrep -uu <pattern> <files> 2>&1| tee <tmp>`. Consequences:

- **Shell globs work when unescaped**: `:grep hello *.lua` expands `*.lua` in
  the shell. A fnameescaped `\*.lua` is a literal filename → `rg: *.lua: No such
  file`. So the target's glob support is limited by the same pre-escaping issue
  `%` had; `expandcmd()` does not glob either.
- Filenames with spaces need escaping: `fnameescape('my file.txt')` →
  `my\ file.txt`, which the shell word-splits correctly.

## Pitfall found while investigating (not fixed): `split_args` strips regex escapes

`split_args` (same commit `5be9a18`) treats `\X` as escaped-`X` for *any* X
(shell-style), inside quotes too. rg patterns lose their backslashes:

```
:Grep \bfoo\bbar file.txt   →   pattern becomes "bfoobbar"   (searches the literal string)
```

Quoting doesn't help: `"..."`/`'...'` only change how spaces split, the
backslash branch runs regardless. Follow-up fix: only treat `\X` as an escape
when X is a space, quote, or backslash — or strip escapes only from the target
arg, never the pattern.

## Verification

Headless integration tests asserted on `vim.fn.getqflist()` (bufnr/lnum), e.g.
`:Grep target %` → 1 entry pointing at the current file. See AGENTS.md
"Testing" for the headless pitfalls (the `:q`-after-`copen` hang, shell-output
invisibility, `-c` backslash mangling).
