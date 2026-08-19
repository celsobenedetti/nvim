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

## Pitfall found while investigating: `split_args` stripped regex escapes (fixed)

The `split_args` tokenizer (introduced in the same commit `5be9a18`) treated
`\X` as escaped-`X` for *any* X (shell-style), inside quotes too. rg patterns
lost their backslashes: `:Grep \bfoo\b file.txt` searched for `bfoob` instead
of the word-boundary regex.

Fix (`288dcdc` follow-up): a backslash now only escapes a following space,
quote, or backslash — anything else (`\b`, `\d`, `\.`, ...) is kept verbatim.
`\bfoo\b` survives as-is; `foo\ bar` still splits into one token. The function
now lives in `lua/lib/strings.lua` as `M.split_args` (unit-tested in
`tests/lib/test_strings.lua`, run by `make test`).

Note this is a *tokenizer* rule: the regex escaping question only exists here
because Lua user commands pass `opts.args` raw. A built-in like `:grep` would
hand the whole line to the ex parser, which has its own escape rules.

## Verification

Headless integration tests asserted on `vim.fn.getqflist()` (bufnr/lnum), e.g.
`:Grep target %` → 1 entry pointing at the current file. See AGENTS.md
"Testing" for the headless pitfalls (the `:q`-after-`copen` hang, shell-output
invisibility, `-c` backslash mangling).
