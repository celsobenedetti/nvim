return {
  { 'williamboman/mason.nvim', opts = true },
  {
    'WhoIsSethDaniel/mason-tool-installer.nvim',
    config = function()
      local ensure_installed = {
        'actionlint', -- Static checker for GitHub Actions workflow files.
        'black', -- Python formatter
        'checkmake', -- Makefile linter
        -- 'deno', -- Deno is a JavaScript, TypeScript, and WebAssembly runtime with secure defaults and a great developer experience.
        'dockerls', -- Docker language server
        'docker-compose-language-server', -- A language server for Docker Compose.
        'eslint', -- JS/TS linter
        'golangci-lint', -- fast Go linters runner. It runs linters in parallel, uses caching, supports yaml config
        'gofumpt', -- Strict Go formatter
        'gopls', -- Go language server
        'goimports', -- Go Imports formatter
        'graphql', -- GQL Language server
        'harper_ls', -- The Grammar Checker for Developers.
        'js-debug-adapter', -- JS/TS debugger
        'json-lsp', -- JSON LSP jsonls
        'isort', -- Python import formatter
        'lua_ls', -- Lua language server

        -- WIP: maybe I'll replacve this
        -- update 2025-07-09: created mfmt project for this
        -- 'markdownlint-cli2', -- Markdown linter an formatter
        -- 'mdformat', --  CommonMark compliant Markdown formatter.

        'oxlint', -- High-performance linter for JavaScript and TypeScript written in Rust.
        'prettierd', -- JS/TS formatter
        'pyright', -- Python language server
        'shfmt', -- sh/bash/zsh formatter
        'shellcheck', -- ShellCheck, a static analysis tool for shell scripts.
        'stylua', -- Lua formatter
        'sqlfluff', -- SQLFluff is a dialect-flexible and configurable SQL linter.
        'tailwindcss-language-server', -- Tailwindcss language server
        'taplo', -- TOML language server / toolkit
        'terraformls', -- Terraform Language Server.
        'tflint', -- A Pluggable Terraform Linter.
        'trivy', -- Find vulnerabilities, misconfigurations, secrets, SBOM in containers, Kubernetes, code repositories, clouds and more.
        'typescript-language-server', -- TS language server
        -- 'vale_ls', -- Markdown linter with LSP providers
        -- 'vtsls', -- VSCode TS language server
        'yaml-language-server', -- Language Server for YAML Files.
        'yq', -- yq is a portable command-line YAML, JSON, XML, CSV, TOML and properties processor.
        -- 'zk', -- zk plain text note-taking assitant - Markdown
      }
      require('mason-tool-installer').setup { ensure_installed = ensure_installed }
    end,
  },
}
