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
            -- lib.blink: fall back to LSP `detail` for import-path hints
            -- (gopls unimported packages); native labelDetails still wins.
            components = {
              label_description = {
                width = { max = 30 },
                text = function(ctx)
                  if ctx.label_description and ctx.label_description ~= '' then
                    return ctx.label_description
                  end

                  local detail = type(ctx.item) == 'table' and ctx.item.detail or nil
                  if type(detail) ~= 'string' then
                    return nil
                  end

                  -- Import paths only: word chars plus ./-:_ (net/http, node:fs, ./utils)
                  local path = detail:match('^"([%w%.%-%_/%:]*)"$')
                  if path == nil or path == '' then
                    return nil
                  end

                  return path
                end,
                highlight = 'BlinkCmpLabelDescription',
              },
            },
          },
        },
        documentation = { auto_show = true, window = { border = 'single' } },
      }
      opts.sources = {
        default = { 'lsp', 'buffer', 'snippets', 'path' },
        per_filetype = {
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
