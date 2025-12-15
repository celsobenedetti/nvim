-- https://github.com/neovim/nvim-lspconfig/blob/a2bd1cf7b0446a7414aaf373cea5e4ca804c9c69/lsp/eslint.lua
-- https://github.com/antfu/eslint-config
local customizations = {
  { rule = 'style/*', severity = 'off', fixable = true },
  { rule = 'format/*', severity = 'off', fixable = true },
  { rule = '*-indent', severity = 'off', fixable = true },
  { rule = '*-spacing', severity = 'off', fixable = true },
  { rule = '*-spaces', severity = 'off', fixable = true },
  { rule = '*-order', severity = 'off', fixable = true },
  { rule = '*-dangle', severity = 'off', fixable = true },
  { rule = '*-newline', severity = 'off', fixable = true },
  { rule = '*quotes', severity = 'off', fixable = true },
  { rule = '*semi', severity = 'off', fixable = true },
}

return {
  settings = {
    -- Silent the stylistic rules in your IDE, but still auto fix them
    rulesCustomizations = customizations,

    -- helps eslint find the eslintrc when it's placed in a subfolder instead of the cwd root
    workingDirectories = { mode = 'auto' },
    format = vim.g.eslint_autoformat,
  },
  root_dir = function(bufnr, on_dir)
    if require('lib.cwd').matches(vim.g.dirs.disable_eslint_lsp) then
      return
    end
    local root_markers = { 'package.json', 'pnpm-lock.yaml', '.git' }
    local project_root = vim.fs.root(bufnr, root_markers) or vim.fn.getcwd() -- We fallback to the current working directory if no project root is found
    on_dir(project_root)
  end,
  filetypes = {
    'astro',
    'css',
    'gql',
    'graphql',
    'html',
    'javascript',
    'javascript.jsx',
    'javascriptreact',
    'json',
    'jsonc',
    'less',
    'markdown',
    'pcss',
    'postcss',
    'scss',
    'svelte',
    'toml',
    'typescript',
    'typescriptreact',
    'typescript.tsx',
    'vue',
    'xml',
    'yaml',
  },
}
