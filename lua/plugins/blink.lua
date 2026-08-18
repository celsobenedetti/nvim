if state.completion == nil then
  state.completion = true
end

return {
  {
    'saghen/blink.cmp',
    dependencies = { 'nvim-mini/mini.snippets' },
    version = '1.*',
    event = { 'InsertEnter', 'CmdlineEnter' },
    opts = function(_, opts)
      opts.enabled = function()
        return vim.bo.buftype ~= 'prompt'
          and vim.bo.filetype ~= 'DressingInput'
          and vim.bo.filetype ~= 'OverseerForm'
          and vim.bo.filetype ~= 'snacks_picker_input'
          and state.completion
      end

      opts.fuzzy = {
        implementation = 'prefer_rust',
      }

      opts.keymap = {
        preset = 'enter',
        ['<C-y>'] = { 'select_and_accept' },
        ['<Tab>'] = false,
      }

      opts.completion = {
        keyword = { range = 'full' },
        menu = {
          border = 'single',
          auto_show = state.completion,
          draw = {
            columns = {
              { 'label', 'label_description', gap = 1 },
              { 'kind_icon', 'kind', gap = 1 },
            },
          },
        },
        documentation = { auto_show = true, window = { border = 'single' } },
      }
      opts.sources = {
        default = { 'lsp', 'buffer', 'snippets', 'path' },
        per_filetype = {
          org = { 'orgmode' },
          mysql = { 'snippets', 'dadbod', 'buffer' },
        },
        providers = {
          orgmode = {
            name = 'Orgmode',
            module = 'orgmode.org.autocompletion.blink',
            fallbacks = { 'buffer' },
          },

          dadbod = { name = 'Dadbod', module = 'vim_dadbod_completion.blink' },
        },
      }

      opts.snippets = {
        preset = 'mini_snippets',
      }

      opts.cmdline = {
        keymap = {
          preset = 'inherit',
          -- disable a keymap from the preset
          ['<CR>'] = false, -- or {}
        },
        completion = {
          list = {
            selection = {
              -- crucial for typing quick commands
              preselect = false,
            },
          },
          menu = {
            auto_show = true,
          },
        },
      }
    end,
  },
}
