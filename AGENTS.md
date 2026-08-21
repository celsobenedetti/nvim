# Neovim configuration

This codebase is a Neovim configuration symlinked to `~/.config/nvim`. It uses
[lazy.nvim](~/.local/share/nvim/lazy/lazy.nvim/README.md) to configure external
plugins.

## Research and document neovim APIs

1. nvim help docs located in: `/usr/local/share/nvim/runtime/doc` (if needed,
   docs in web:
   [Neovim API web reference Reference](https://neovim.io/doc/user/api.html))
2. Neovim source code in `~/local/neovim/`

When valuable populate your findings in a `docs` file.

### external plugins

If task pertains to particular external plugins, you can research code in
`~/.local/share/nvim/lazy/{plugin_name}`

## Favor simplicity and standard neovim features over custom solutions and over engineering

Before implementing features research if Vim / Neovim have native ways to
achieve the goal. This involves reducing complexity throughout the config.
ALWAYS ask for clarification if unclear.

## Favor Neovim Lua APIs over Vimscript

For all new feature we do implement, avoid Vimscript and use the Neovim Lua
APIs.

## Testing

Unit tests run through `make test` (luajit with mocked `vim`, see `tests/`).

Integration-test user commands against real nvim (run from the repo root):
`nvim --headless -u NONE --cmd "set rtp^=." -c "luafile after/plugin/grep.lua" -c "Grep foo %" -c "qa!"`.
The `set rtp^=.` prepends the repo to 'runtimepath' so `require('lib.*')`
resolves here — with `-u NONE` nvim's rtp still has `~/.config/nvim` first (the
live config, which may lag this worktree) and its Lua loader wins over
`package.path`.

- End every headless `-c` chain with `qa!` (or `cquit`): a `:q` that closes one
  of several windows leaves headless nvim idling in its event loop forever —
  only a `:q` on the _last_ window exits. `:cclose` then `:q` also works.
- Assert results with `vim.fn.getqflist()` (bufnr/lnum): `:grep` shells out to
  rg and the `:!` output line is invisible in headless mode.
- Test argument parsing (quoting, backslash escapes) with `nvim -l`, which runs
  Lua and exits cleanly — `-c` strings mangle regex backslashes through bash
  quoting, `-c` parsing, and `split_args`.
