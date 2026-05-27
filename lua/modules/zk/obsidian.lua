local strings = require('lib.strings')
local visual = require('lib.visual')

local function create_note_from_selection()
  local text = visual.get_selection()
  if not text or #text == 0 then
    return
  end
  local obsidian = require('obsidian')
  local title = strings.trim(text)

  obsidian.Note
    .create({
      id = title,
      title = title,
    })
    :save({
      path = vim.g.env.notes.OBSIDIAN_INBOX .. '/' .. title .. '.md',
      insert_frontmatter = false,
      -- update_content = function()
      --   return { '#seed' }
      -- end,
    })

  visual.replace('[[' .. title .. ']]')
end

local function notes_env()
  if not vim.g.env or not vim.g.env.notes then
    return nil
  end
  return vim.g.env.notes
end

return {
  'obsidian-nvim/obsidian.nvim',
  version = '*',
  vscode = false,
  event = function()
    local env = notes_env()
    if not env or not env.NOTES then
      return {}
    end
    return {
      'BufReadPre ' .. env.NOTES .. '/**/*',
      'BufNewFile ' .. env.NOTES .. '/**/*',
    }
  end,
  keys = function()
    local env = notes_env()
    if not env or not env.NOTES then
      return {}
    end
    local notes = env.NOTES
    local icons = (vim.g.icons or {}).notes or ''

    return {
      {
        '<leader>zz',
        function()
          Snacks.picker.files({
            title = icons .. 'notes',
            cwd = notes,
            confirm = function(picker, item)
              picker:close()
              require('lib.notes').focus_or_create_notes_tab(function()
                vim.cmd('e ' .. item.file)
              end)
            end,
          })
        end,
        desc = 'search notes',
      },
      {
        '<leader>zZ',
        function()
          Snacks.picker.grep({
            cwd = notes,
            title = icons .. 'search through notes',
            confirm = function(_, item)
              require('lib.notes').focus_or_create_notes_tab(function()
                vim.cmd('e ' .. item.file)
              end)
            end,
          })
        end,
        desc = 'Grep through notes',
      },
      { '<leader>oO', '<cmd>Obsidian open<CR>', desc = 'Open in Obsidian' },
      { '<leader>ob', '<cmd>Obsidian backlinks<CR>', desc = 'Backlinks' },
      { '<leader>od', '<cmd>Obsidian dailies<CR>', desc = 'Daily notes' },
      { '<leader>ol', '<cmd>Obsidian links<CR>', desc = 'Links in note' },
      { '<leader>ch', '<cmd>Obsidian check<CR>', desc = 'Health check' },
      { '<leader>oR', '<cmd>Obsidian rename<CR>', desc = 'Rename note' },
      { '<leader>toc', '<cmd>Obsidian toc<CR>', desc = 'Table of contents' },
      { '<leader>n', create_note_from_selection, mode = 'v', desc = 'Create note from selection' },
    }
  end,
  config = function()
    local env = notes_env()
    if not env or not env.NOTES then
      return {}
    end

    local notes = env.NOTES
    local inbox_subdir = env.OBSIDIAN_INBOX:gsub(notes .. '/', '')

    require('obsidian').setup({
      legacy_commands = false,
      workspaces = {
        { name = 'notes', path = notes },
        { name = 'archives', path = env.ARCHIVES },
      },
      notes_subdir = inbox_subdir,
      new_notes_location = 'notes_subdir',
      daily_notes = {
        folder = 'daily',
      },
      templates = {
        folder = env.ASSETS .. '/templates',
        date_format = '%F',
        time_format = '%H:%M',
      },
      frontmatter = {
        enabled = false,
      },
      attachments = {
        folder = env.ATTACHMENTS,
        confirm_img_paste = true,
      },
      completion = {
        blink = true,
        min_chars = 2,
      },
      ui = {
        enable = true,
      },
      note_id_func = function(title, path)
        if title then
          return title
        end
        if path then
          return path.stem or path.name or path.filename
        end
        Snacks.notify.error('BUG: BAD_ID')
        return 'BUG: BAD_ID'
      end,
      picker = {
        name = 'snacks.pick',
        note_mappings = {
          new = '<C-x>',
          insert_link = '<C-l>',
        },
      },
    })

    vim.api.nvim_set_hl(
      0,
      'ObsidianRefText',
      { bg = 'none', fg = vim.g.colors.links or vim.g.colors.purple or vim.g.colors.primary, underline = true }
    )
  end,
  dependencies = {
    'nvim-lua/plenary.nvim',
  },
}
