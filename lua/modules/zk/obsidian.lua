local strings = require 'lib.strings'
local visual = require 'lib.visual'

return {
  {
    'obsidian-nvim/obsidian.nvim',
    version = '*', -- recommended, use latest release instead of latest commit
    vscode = false,
    ft = { 'org' },
    keys = {
    -- stylua: ignore start
      { "<leader>zz", function() Snacks.picker.grep({cwd = vim.g.notes.NOTES}) end, desc = "Grep through notes", },
      { "<leader>zZ", function() Snacks.picker.files({cwd=vim.g.notes.NOTES, title = "notes", }) end, desc = "search notes", },
      { '<leader>oO', ':Obsidian open<CR>' },
      { '<leader>ob', ':Obsidian backlinks<CR>' },
      { '<leader>od', ':Obsidian dailies<CR>' },
      { '<leader>ol', ':Obsidian links<CR>' },
      -- { '<leader>ot', ':ObsidianTags<CR>' },
      { '<leader>ch', ':Obsidian check<CR>' },
      { '<leader>oR', ':Obsidian rename<CR>' },
      { '<leader>toc', ':Obsidian toc<CR>' },

      {
        '<leader>n',
        function()
          local text = visual.get_selection()
          if not text or #text == 0 then
            return
          end
          local obsidian = require 'obsidian'

          local title = strings.trim(text)
          local id = strings.slugify(text)
          obsidian.Note
            .create({
              id = id,
              title = title,
            })
            :save()

          if vim.bo.filetype == 'markdown' then
            -- we only want to add use the title syntax in markdown file, otherwise we want to just add the id
            visual.replace('[[' .. id .. '|' .. title .. ']]')
          else
            visual.replace('[[' .. id .. ']]')
          end
        end,
        mode = 'v',
      },

      {
        '<leader>oo',
        function()
          require('lib.zk').open_orgmode_or_obsidian_link()
        end,
        desc = 'Open orgmode or obsidian link',
      },
      {
        '<leader>ov',
        function()
          vim.cmd 'vsplit'
          require('lib.zk').open_orgmode_or_obsidian_link()
        end,
        desc = 'Open orgmode or obsidian link (vertical split)',
      },

      -- stylua: ignore end
    },
    cond = function()
      if require('lib.cwd').matches { 'journals' } then
        return false
      end

      local path = vim.fn.expand '%:p'
      local is_templates = path:find 'templates'

      return not is_templates
    end,
    opts = function(_, opts)
      opts.legacy_commands = false
      opts.new_notes_location = vim.g.notes.INBOX
      opts.workspaces = {
        { name = 'notes', path = vim.g.notes.NOTES },
        { name = 'archives', path = vim.g.notes.ARCHIVES },
        { name = 'zk', path = vim.g.notes.ZK },
      }

      opts.attachments = {
        -- TODO: handle archive/notes vaults
        img_folder = 'archives/assets/imgs',
        img_name_func = function()
          return string.format('Pasted image %s', os.date '%Y%m%d%H%M%S')
        end,
        confirm_img_paste = true,
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
        --   [" "] = { char = "󰄱", hl_groupth
        --   = "ObsidianTodo" },
        --   [">"] = { char = "", hl_group = "ObsidianRightArrow" },
        --   ["~"] = { char = "x", hl_group = "ObsidianTilde" },
        --   ["x"] = { char = "✔", hl_group = "ObsidianDone" },
        -- },
      }

      --- @param title string|?
      --- @param path obsidian.Path|?
      opts.note_id_func = function(title, path)
        if title ~= nil then
          return title
        end

        if path ~= nil then
          return path.stem or path.name or path.filename
        end

        return nil
      end

      opts.picker = {
        -- Set your preferred picker. Can be one of 'telescope.nvim', 'fzf-lua', 'mini.pick' or 'snacks.pick'.
        name = 'snacks.pick',
        -- Optional, configure key mappings for the picker. These are the defaults.
        -- Not all pickers support all mappings.
        note_mappings = {
          -- Create a new note from your query.
          new = '<C-x>',
          -- Insert a link to the selected note.
          insert_link = '<C-l>',
        },
        -- tag_mappings = {
        --   -- Add tag(s) to current note.
        --   tag_note = '<C-x>',
        --   -- Insert a tag at the current location.
        --   insert_tag = '<C-l>',
        -- },
        -- tag_mappings = {
        --   -- Add tag(s) to current note.
        --   tag_note = '<C-x>',
        --   -- Insert a tag at the current location.
        --   insert_tag = '<C-l>',
        -- },
      }

      -- -- TODO: costumize frontmatter fucntion so we don't care about frontmatter for certain files
      -- opts.note_frontmatter_func = function(note)
      --   local frontmatter = {
      --     id = note.id,
      --     aliases = note.aliases,
      --     title = note.title,
      --     date = note.date,
      --   }
      --
      --   if note.tags ~= nil and not vim.tbl_isempty(note.tags) then
      --     frontmatter.tags = note.tags
      --   end
      --
      --   if note.metadata ~= nil and not vim.tbl_isempty(note.metadata) then
      --     for k, v in pairs(note.metadata) do
      --       frontmatter[k] = v
      --     end
      --   end
      --   return frontmatter
      -- end

      ---@param spec { id: string, dir: obsidian.Path, title: string|? }
      ---@return string|obsidian.Path The full path to the new note.
      opts.note_path_func = function(spec)
        local f = spec.title or spec.id
        local path = spec.dir / strings.slugify(f)
        return path:with_suffix '.md'
      end
    end,
    dependencies = {
      'nvim-lua/plenary.nvim',
    },
  },
}
