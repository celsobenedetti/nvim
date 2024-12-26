return {
  { 'williamboman/mason.nvim', opts = true },
  {
    'WhoIsSethDaniel/mason-tool-installer.nvim',
    config = function()
      local ensure_installed = {
        'black', -- Python formatter
        'checkmake', -- Makefile linter
        'deno', -- Deno is a JavaScript, TypeScript, and WebAssembly runtime with secure defaults and a great developer experience.
        'dockerls', -- Docker language server
        'eslint', -- JS/TS linter
        'gofumpt', -- Strict Go formatter
        'gopls', -- Go language server
        'goimports', -- Go Imports formatter
        'graphql', -- GQL Language server
        'js-debug-adapter', -- JS/TS debugger
        'json-lsp', -- JSON LSP jsonls
        'isort', -- Python import formatter
        'lua_ls', -- Lua language server
        'markdownlint-cli2', -- Markdown linter an formatter
        'prettierd', -- JS/TS formatter
        'pyright', -- Python language server
        'shfmt', -- sh/bash/zsh formatter
        'shellcheck', -- ShellCheck, a static analysis tool for shell scripts.
        'stylua', -- Lua formatter
        'tailwindcss-language-server', -- Tailwindcss language server
        'taplo', -- TOML language server / toolkit
        'typescript-language-server', -- TS language server
        'vale_ls', -- Markdown linter with LSP providers
        -- 'vtsls', -- VSCode TS language server
        'zk', -- zk plain text note-taking assitant - Markdown
      }
      require('mason-tool-installer').setup { ensure_installed = ensure_installed }
    end,
  },
}
