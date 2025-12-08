local cwd = require 'lib.cwd'
local eslint_projects = { 'ecommerce' }

return {
  'stevearc/conform.nvim',
  lazy = false,
  enabled = function()
    -- avoid formatting files in lazy.nvim managed repos
    return not cwd.matches { 'lazy' }
  end,
  keys = {
    {
      '<leader>cF',
      function()
        require('conform').format { formatters = { 'injected' }, timeout_ms = 3000 }
      end,
      mode = { 'n', 'x' },
      desc = 'Format Injected Langs',
    },
  },
  config = function()
    local use_eslint = false
    for _, project in ipairs(eslint_projects) do
      if cwd.matches { project } then
        use_eslint = true
        break
      end
    end
    local fmt_js = use_eslint and { lsp_format = 'last', async = true } or { 'prettier' }

    require('conform').setup {
      format_on_save = {
        lsp_format = 'fallback',
        timeout_ms = 500,
      },

      formatters_by_ft = {
        -- markdown = { 'mfmt' },
        -- org = { 'mfmt_org' },
        -- gitcommit = { 'mfmt' },
        --
        lua = { 'stylua' },
        sh = { 'shfmt' },
        css = fmt_js,
        json = fmt_js,
        javascript = fmt_js,
        typescript = fmt_js,
        typescriptreact = fmt_js,
        vue = fmt_js,

        odin = { 'odinfmt' },
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
    }
  end,
}
