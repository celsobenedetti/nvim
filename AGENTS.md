# AGENTS.md - Neovim Configuration Development Guidelines


## Context

When asked about neovim APIs:
- first research the local help docs in: `/usr/share/nvim/runtime/doc/`
- then the web [Neovim API Reference](https://neovim.io/doc/user/api.html) if needed.
- ALWAYS populate your findings in a `neovim_api_findings.md` file.


## Code Style Guidelines

### General Conventions
- **Type hints**: Uses EmmyLua annotations (`---@type`, `---@param`, etc.)
- **Language**: Lua (Neovim configuration)
- **Module pattern**: Use `local M = {}` pattern, return `M` at end
- **File organization**: 
  - `lua/init/` - Core initialization
  - `lua/modules/` - Plugin configurations organized by category
  - `lua/lib/` - Utility libraries
  - `lua/config/` - Configuration files
  - `after/plugin/` - Plugin-specific configurations

### Naming Conventions
- **Variables**: `snake_case` (e.g., `local my_variable`)
- **Functions**: `snake_case` (e.g., `function my_function()`)
- **Modules**: `snake_case` file names
- **Constants**: `UPPER_CASE` or `PascalCase` for global constants
- **Plugin names**: Follow the plugin's conventional naming
