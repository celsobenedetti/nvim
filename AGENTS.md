# AGENTS.md - Neovim Configuration Development Guidelines

This document provides guidelines for agentic coding assistants working on this Neovim configuration codebase.
It covers build/lint/test commands, code style conventions, and development practices.

## Build/Lint/Test Commands

### Testing
- **Run all tests**: `make test` (executes `./scripts/test`)
- **Run single test file**: Currently not supported - the test script referenced in Makefile doesn't exist
- **Test framework**: No dedicated testing framework configured. Uses basic shell script testing.

### Linting
- **Lint codebase**: Not directly available via command line
- **Linting tools**:
  - `nvim-lint` for various filetypes (lua, go, typescript, javascript, vue, etc.)
  - Linters configured per filetype in `lua/modules/core/lint.lua`

### Formatting
- **Format code**: `make format` (uses `stylua .`)
- **Check formatting**: `stylua --check .`
- **Formatter**: `stylua` with configuration in `stylua.toml`

### Type Checking
- **Type checking**: Not configured - Lua is dynamically typed
- **Type hints**: Uses EmmyLua annotations (`---@type`, `---@param`, etc.)

## Code Style Guidelines

### General Conventions
- **Language**: Lua (Neovim configuration)
- **Module pattern**: Use `local M = {}` pattern, return `M` at end
- **File organization**: 
  - `lua/init/` - Core initialization
  - `lua/modules/` - Plugin configurations organized by category
  - `lua/lib/` - Utility libraries
  - `lua/config/` - Configuration files
  - `after/plugin/` - Plugin-specific configurations

### Formatting Rules
- **Indentation**: 2 spaces (configured in `stylua.toml`)
- **Line endings**: Unix (`\n`)
- **Quote style**: Single quotes preferred (`'`) for strings
- **Column width**: 120 characters
- **Parentheses**: Always use parentheses around function calls
- **Trailing commas**: Use consistently in tables

### Naming Conventions
- **Variables**: `snake_case` (e.g., `local my_variable`)
- **Functions**: `snake_case` (e.g., `function my_function()`)
- **Modules**: `snake_case` file names
- **Constants**: `UPPER_CASE` or `PascalCase` for global constants
- **Plugin names**: Follow the plugin's conventional naming

### Imports and Dependencies
- **Require statements**: Use `local module = require('module.path')`
- **Import order**: 
  1. Standard library modules
  2. Local modules (`lib.*`, `config.*`)
  3. Plugin-specific imports
- **Lazy loading**: Prefer lazy loading for plugins when possible

### Error Handling
- **Error patterns**: Use `assert()` for programming errors, `error()` for runtime errors
- **Plugin errors**: Use `Snacks.notify` for user-facing notifications
- **Graceful degradation**: Handle missing dependencies gracefully

### Plugin Configuration Patterns
- **Structure**: Return table with plugin spec for lazy.nvim
- **Keys**: Define keybindings in the `keys` field
- **Config**: Use `config` function for setup
- **Events**: Use appropriate `event` triggers for lazy loading

### Examples

#### Module Structure
```lua
local M = {}

---@param opts table
function M.setup(opts)
  -- implementation
end

return M
```

#### Plugin Configuration
```lua
return {
  'plugin/name',
  event = 'VeryLazy',
  config = function()
    require('plugin').setup({
      -- options
    })
  end,
  keys = {
    { '<leader>key', '<cmd>Command<cr>', desc = 'Description' }
  }
}
```

#### Function Documentation
```lua
---@param param_name param_type Description of parameter
---@return return_type Description of return value
function M.my_function(param_name)
  -- implementation
end
```

### Best Practices
- **Performance**: Be mindful of startup time, use lazy loading
- **Consistency**: Follow existing patterns in the codebase
- **Documentation**: Add EmmyLua annotations for complex functions
- **Testing**: Manual testing preferred; add integration tests when possible
- **Security**: Avoid executing untrusted code; validate inputs
- **Maintainability**: Keep functions small and focused; use clear naming

### Common Patterns in This Codebase
- **Global configuration**: Use `vim.g.*` for global variables
- **Icons**: Access via `vim.g.icons.*`
- **Colors**: Access via `vim.g.colors.*`
- **Autocommands**: Use `vim.api.nvim_create_autocmd`
- **Keymaps**: Use `map()` function (defined globally)
- **Notifications**: Use `Snacks.notify()` for user feedback

### Development Workflow
1. Make changes to Lua files
2. Format with `make format`
3. Restart Neovim or reload configuration
4. Test functionality manually
5. Commit changes following conventional commit format

### File Types and Tools
- **Lua**: Primary language - linted with `luac`, formatted with `stylua`
- **Shell scripts**: Linted with `shellcheck`, formatted with `shfmt`
- **Go**: Linted with `golangcilint`, formatted with `goimports` + `gofmt`
- **TypeScript/JavaScript/Vue**: Linted with `oxlint`, formatted with `prettier` or ESLint
- **JSON**: Formatted with `prettier`

This configuration emphasizes performance, consistency, and maintainability while leveraging Neovim's ecosystem effectively.</content>
<parameter name="filePath">/home/celso/.config/nvim/AGENTS.md


## Context

Neovim help docs are stored in `/usr/share/nvim/runtime/doc/`
