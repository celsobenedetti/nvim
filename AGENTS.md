# AGENTS.md - Neovim Configuration Development Guidelines

## Rules

### Research and document neovim APIs
- first research the local help docs in: `/usr/share/nvim/runtime/doc/`
- then the web [Neovim API Reference](https://neovim.io/doc/user/api.html) if needed.
- ALWAYS populate your findings in a `docs` file.

### Favor simplicity and standard features over new features and over engineering

Before implementing features research if Vim / Neovim have native ways to achieve the goal.
This involves reducing complexity throughout the config.
ALWAYS ask for clarification if unclear.

### Favor Neovim Lua APIs over Vimscript
For all new feature we do implement, avoid Vimscript and use the Neovim Lua APIs.
