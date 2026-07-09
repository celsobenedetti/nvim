local highlights_to_hide = {
  'ObsidianRefText',
}

local saved_highlights = {}

local function toggle_highlights(hide)
  if hide then
    for _, name in ipairs(highlights_to_hide) do
      local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = name, link = false })
      if ok and hl and not vim.tbl_isempty(hl) then
        saved_highlights[name] = vim.deepcopy(hl)
        vim.api.nvim_set_hl(0, name, { fg = 'none', bg = 'none' })
      end
    end
  else
    for name, hl in pairs(saved_highlights) do
      hl.default = nil
      vim.api.nvim_set_hl(0, name, hl)
    end
    saved_highlights = {}
  end
end

return {
  {
    'folke/snacks.nvim',
    keys = {
      {
        '<leader>tw',
        function()
          MiniHipatterns.toggle()
          if Snacks.dim.enabled then
            vim.wo.number = true
            Snacks.dim.disable()
            Snacks.indent.enable()
            vim.cmd('Gitsigns attach')
            toggle_highlights(false)
          else
            vim.wo.number = false
            Snacks.indent.disable()
            Snacks.dim.enable({
              scope = {
                min_size = 5,
                max_size = 20,
              },
            })
            vim.cmd('Gitsigns detach')
            toggle_highlights(true)
          end
        end,
        desc = 'toggle dim',
      },
    },
    opts = function(_, opts)
      --- @type snacks.zen.Config
      opts.dim = {
        scope = {
          min_size = 1,
          max_size = 1,
          siblings = false,
        },
      }

      opts.scope = {
        treesitter = {
          enabled = true,
          injections = true,
          blocks = {
            enabled = false,
            'function_declaration',
            'function_definition',
            'method_declaration',
            'method_definition',
            'class_declaration',
            'class_definition',
            'do_statement',
            'while_statement',
            'repeat_statement',
            'if_statement',
            'for_statement',
            'subsection',
            'property_drawer',
          },
          field_blocks = {
            'subsection',
            'property_drawer',
          },
        },
      }

      vim.api.nvim_set_hl(0, 'SnacksDim', {
        bg = 'none',
        fg = vim.g.colors.bg,
        bold = false,
        italic = false,
        underline = false,
        undercurl = false,
        strikethrough = false,
      })
    end,
  },
}
