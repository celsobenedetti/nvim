# Neovim configuration

This codebase is a Neovim configuration symlinked to `~/.config/nvim`. It uses
[lazy.nvim](~/.local/share/nvim/lazy/lazy.nvim/README.md) to configure external
plugins.

## Research and document neovim APIs

nvim help docs located in: `/usr/local/share/nvim/runtime/doc` if needed:
[Neovim API web reference Reference](https://neovim.io/doc/user/api.html).

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
