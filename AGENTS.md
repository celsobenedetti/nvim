# Agent Instructions for Neovim Configuration

## docs

LSP: https://neovim.io/doc/user/lsp.html
LazyVim configuration: https://github.com/LazyVim/lazyvim.github.io/tree/main/docs/configuration
conform.nvim: https://github.com/stevearc/conform.nvim/blob/master/doc/recipes.md


## Build/Lint/Test Commands
- **Run all tests**: `make test` or `./scripts/test`
- **Format code**: `make format` or `stylua .`
- **Lint code**: `:LintInfo` (shows configured linters for current filetype)
- **Run single test**: `nvim -l ./lua/tests/init.lua` (runs all tests, no single test isolation)

## Code Style Guidelines

- snake_case when possible
- Use EmmyLua annotations: `@param`, `@return`, `@module`

### Testing
- Use custom BDD framework: `describe`/`it`/`assert`
- Test files in `lua/tests/` directory
- Assertions: `assert.equals`, `assert.same`, `assert.is_nil`, etc.
- Run tests with descriptive messages</content>
<parameter name="filePath">/home/celso/.config/nvim/AGENTS.md
