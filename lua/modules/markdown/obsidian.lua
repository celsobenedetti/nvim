return {
  {
    'epwalsh/obsidian.nvim',
    version = '*', -- recommended, use latest release instead of latest commit
    vscode = false,
    lazy = true,
    ft = 'markdown',
    keys = {
      { '<leader>zk', ':ObsidianSearch<CR>' },
      { '<leader>oo', ':ObsidianOpen<CR>' },
      { '<leader>ob', ':ObsidianBacklinks<CR>' },
      { '<leader>ol', ':ObsidianLinks<CR>' },
      { '<leader>ot', ':ObsidianTags<CR>' },
      { '<leader>ch', ':ObsidianToggleCheckbox<CR>' },
    },
    cond = function()
      local path = vim.fn.expand '%:p'

      local is_notes = path:find 'notes'
      local is_templates = path:find 'templates'
      local is_gpt_chat = path:find(C.opt.gpt_chats_path)

      return is_notes and not is_templates and not is_gpt_chat
    end,
    opts = function(_, opts)
      opts.new_notes_location = 'notes_subdir'
      opts.workspaces = {
        {
          name = 'notes',
          path = '~/notes',
          overrides = {
            notes_subdir = 'inbox',
          },
        },
      }
      opts.ui = {
        enable = false,
        checkboxes = {
          [' '] = { char = '󰄱', hl_group = 'ObsidianTodo' },
          ['>'] = { char = '', hl_group = 'ObsidianRightArrow' },
          ['~'] = { char = 'x', hl_group = 'ObsidianTilde' },
          ['x'] = { char = '✔', hl_group = 'ObsidianDone' },
        },
      }
      opts.note_id_func = function(title)
        return title
      end
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
    end,
    dependencies = {
      'nvim-lua/plenary.nvim',
    },
  },
}
