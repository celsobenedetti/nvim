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
  on_attach = function(client, bufnr)
    vim.api.nvim_create_autocmd('BufWritePre', {
      buffer = bufnr,
      command = 'LspEslintFixAll',
    })
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
