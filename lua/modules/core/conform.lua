local cwd = require('lib.cwd')

return {
  'stevearc/conform.nvim',
  lazy = false,
  enabled = function()
    return not cwd.matches(vim.g.dirs.dont_format)
  end,
  keys = {
    {
      '<leader>cF',
      function()
        require('conform').format({ formatters = { 'injected' }, timeout_ms = 3000 })
      end,
      mode = { 'n', 'x' },
      desc = 'Format Injected Langs',
    },
  },
  config = function()
    -- BUG: this only runs when neovim starts up, if we change the dir later, this config is already set
    local use_eslint = false
    for _, project in ipairs(vim.g.dirs.format_with_eslint) do
      if cwd.matches({ project }) then
        use_eslint = true
        break
      end
    end
    local fmt_js = use_eslint and { lsp_format = 'fallback', async = true } or { 'prettier' }

    require('conform').setup({
      format_on_save = function()
        if not vim.g.autoformat then
          return nil
        end

        return {
          lsp_format = 'fallback',
          timeout_ms = 500,
        }
      end,

      formatters_by_ft = {
        -- markdown = { 'mfmt' },
        -- org = { 'mfmt_org' },
        -- gitcommit = { 'mfmt' },
        --
        css = fmt_js,
        go = { 'goimports', 'gofmt' },
        html = { 'prettier' },
        javascript = fmt_js,
        json = fmt_js,
        lua = { 'stylua' },
        odin = { 'odinfmt' },
        sh = { 'shfmt' },
        typescript = fmt_js,
        typescriptreact = fmt_js,
        vue = fmt_js,
      },
      formatters = {
        goimports = { prepend_args = { '-local', 'github.com/celsobenedetti/' } },
        shfmt = { prepend_args = { '--indent', '4' } },
        -- mfmt = { command = 'mfmt' },
        -- mfmt_org = { command = 'mfmt', prepend_args = { '--parser=orgmode' } },
        prettierd = {
          env = {
            PRETTIERD_LOCAL_PRETTIER_ONLY = 'true',
          },
        },
      },
    })
  end,
}
