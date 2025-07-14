local string_utils = require 'lib.utils.string'

return {

  {
    'obsidian-nvim/obsidian.nvim',
    version = '*', -- recommended, use latest release instead of latest commit
    vscode = false,
    -- lazy = true,
    ft = { 'markdown', 'org' },
    keys = {
      { '<leader>zk', ':Obsidian search<CR>' },
      { '<leader>oO', ':Obsidian open<CR>' },
      { '<leader>ob', ':Obsidian backlinks<CR>' },
      { '<leader>ol', ':Obsidian links<CR>' },
      -- { '<leader>ot', ':ObsidianTags<CR>' },
      { '<leader>ch', ':Obsidian toggleCheckbox<CR>' },
      { '<leader>zz', ':Obsidian quick_switch<CR>' },
      { '<leader>oR', ':Obsidian rename<CR>' },
      { '<leader>n', ':Obsidian link_new<CR>', mode = 'v' },
    },
    cond = function()
      if C.cwd.is_llm_chats() then
        return false
      end

      local path = vim.fn.expand '%:p'
      local is_templates = path:find 'templates'

      return not is_templates
    end,
    opts = function(_, opts)
      opts.new_notes_location = 'notes_subdir'
      opts.workspaces = {
        {
          name = 'notes',
          path = '~/notes',
          overrides = {
            notes_subdir = '0-inbox',
          },
        },
      }

      opts.completion = {
        -- Enables completion using nvim_cmp
        nvim_cmp = false,
        -- Enables completion using blink.cmp
        blink = true,
        -- Trigger completion at 2 chars.
        min_chars = 2,
      }
      opts.ui = {
        enable = false,
        -- checkboxes = {
        --   [' '] = { char = '󰄱', hl_group = 'ObsidianTodo' },
        --   ['>'] = { char = '', hl_group = 'ObsidianRightArrow' },
        --   ['~'] = { char = 'x', hl_group = 'ObsidianTilde' },
        --   ['x'] = { char = '✔', hl_group = 'ObsidianDone' },
        -- },
      }
      opts.note_id_func = function(title)
        return title
      end

      -- TODO: costumize frontmatter fucntion so we don't care about frontmatter for certain files
      opts.note_frontmatter_func = function(note)
        local frontmatter = {
          id = note.id,
          aliases = note.aliases,
          title = note.title,
          date = note.date,
          tags = note.tags,
        }
        if note.metadata ~= nil and not vim.tbl_isempty(note.metadata) then
          for k, v in pairs(note.metadata) do
            frontmatter[k] = v
          end
        end
        return frontmatter
      end

      opts.note_path_func = function(spec)
        local path = spec.dir / string_utils.slugify(spec.title)
        return path:with_suffix '.md'
      end
    end,
    dependencies = {
      'nvim-lua/plenary.nvim',
    },
  },
}
