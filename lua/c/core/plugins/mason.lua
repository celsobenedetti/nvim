return {
  { 'williamboman/mason.nvim', opts = true },
  {
    'WhoIsSethDaniel/mason-tool-installer.nvim',
    config = function()
      local ensure_installed = {
        'black', -- Python formatter
        'checkmake', -- Makefile linter
        'dockerls', -- Docker language server
        'eslint', -- JS/TS linter
        'gopls', -- Go language server
        'isort', -- Python import formatter
        'js-debug-adapter', -- JS/TS debugger
        'lua_ls', -- Lua language server
        'markdownlint-cli2', -- Markdown linter an formatter
        'prettierd', -- JS/TS formatter
        'pyright', -- Python language server
        'shfmt', -- sh/bash/zsh formatter
        'stylua', -- Lua formatter
        'tailwindcss-language-server', -- Tailwindcss language server
        'taplo', -- TOML language server / toolkit
        -- 'tsserver', -- TS language server
        'vale_ls', -- Markdown linter with LSP providers
        'vtsls', -- VSCode TS language server
        'zk', -- zk plain text note-taking assitant - Markdown
      }
      require('mason-tool-installer').setup { ensure_installed = ensure_installed }
    end,
  },
}
