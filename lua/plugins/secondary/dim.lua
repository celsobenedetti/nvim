local highlights_to_hide = {
  'ObsidianRefText',
}

local saved_highlights = {}

local dim_scope_patched = false

-- snacks.dim only recomputes a window's scope on cursor movement, so
-- unfocused splits keep showing their last-active-line scope instead of
-- going fully dim. Patch on_win so only the current window gets
-- scope-based dimming; every other window is dimmed edge-to-edge.
local function patch_dim_scope()
  if dim_scope_patched then
    return
  end
  dim_scope_patched = true

  local dim = require('snacks.dim')
  local original_on_win = dim.on_win
  local ns = vim.api.nvim_create_namespace('snacks_dim')

  dim.on_win = function(win, buf, top, bottom)
    if win ~= vim.api.nvim_get_current_win() then
      for l = top, bottom do
        vim.api.nvim_buf_set_extmark(buf, ns, l - 1, 0, {
          end_row = l,
          end_col = 0,
          hl_group = 'SnacksDim',
          ephemeral = true,
        })
      end
      return
    end
    original_on_win(win, buf, top, bottom)
  end
end

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
            -- vim.wo.number = true
            Snacks.dim.disable()
            Snacks.indent.enable()
            vim.cmd('Gitsigns attach')
            toggle_highlights(false)
          else
            -- vim.wo.number = false
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
      patch_dim_scope()

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

      local bg = lib.colors.darken(colors.bg, 0.1)
      vim.api.nvim_set_hl(0, 'SnacksDim', {
        bg = bg,
        fg = bg,
        bold = false,
        italic = false,
        underline = false,
        undercurl = false,
        strikethrough = false,
      })
    end,
  },
}
