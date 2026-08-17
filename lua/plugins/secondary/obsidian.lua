local function create_note_from_selection()
  if vim.bo.filetype ~= 'markdown' then
    return
  end

  local text = lib.visual.get_selection()
  if not text or #text == 0 then
    return
  end
  local obsidian = require('obsidian')
  local title = lib.strings.trim(text)

  obsidian.Note
      .create({
        id = title,
        title = title,
      })
      :save({
        path = state.env.notes.OBSIDIAN_INBOX .. '/' .. title .. '.md',
        insert_frontmatter = false,
        update_content = function()
          return { '' }
        end,
      })

  lib.visual.replace('[[' .. title .. ']]')
end

return {
  'obsidian-nvim/obsidian.nvim',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'ibhagwan/fzf-lua',
  },
  version = '*',
  vscode = false,
  cmd = { 'Obsidian' },
  event = function()
    return {
      'BufReadPre ' .. state.env.notes.NOTES .. '/**/*',
      'BufNewFile ' .. state.env.notes.NOTES .. '/**/*',
      'BufReadPre ' .. state.env.notes.OBSIDIAN_VAULT_WORK .. '/**/*',
      'BufNewFile ' .. state.env.notes.OBSIDIAN_VAULT_WORK .. '/**/*',
    }
  end,
  keys = function()
    local vault = state.env.notes.NOTES
    local icons = (state.icons or {}).notes or ''

    return {
      -- {
      --   '<leader>zz',
      --   function()
      --     Snacks.picker.files({
      --       title = icons .. 'notes',
      --       cwd = vault,
      --       confirm = function(picker, item)
      --         picker:close()
      --         require('lib.notes').focus_or_create_notes_tab(function()
      --           vim.cmd('e ' .. item.file)
      --         end)
      --       end,
      --     })
      --   end,
      --   desc = 'search notes',
      -- },
      {
        '<leader>zZ',
        function()
          Snacks.picker.grep({
            cwd = vault,
            title = icons .. 'search through notes',
            confirm = function(_, item)
              lib.notes.focus_or_create_notes_tab(function()
                vim.cmd('e ' .. item.file)
              end)
            end,
          })
        end,
        desc = 'Grep through notes',
      },
      {
        '<leader>md',
        function()
          -- local ui_opts = Obsidian and Obsidian.opts and Obsidian.opts.ui
          -- if not ui_opts then
          --   return
          -- end
          -- ui_opts.enable = not ui_opts.enable
          -- if ui_opts.enable then
          --   require('obsidian.ui').update()
          -- else
          --   local ns = vim.api.nvim_create_namespace('ObsidianUI')
          --   for _, buf in ipairs(vim.api.nvim_list_bufs()) do
          --     if vim.api.nvim_buf_is_valid(buf) then
          --       vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
          --     end
          --   end
          -- end

          local enabled = Obsidian.opts.ui.enable
          Obsidian.opts.ui.enable = not enabled
          if enabled then
            local ns = vim.api.nvim_create_namespace('ObsidianUI')
            vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)
          else
            require('obsidian.ui').update(0)
          end
        end,

        desc = 'Toggle Obsidian UI',
      },
      { '<leader>oO', '<cmd>Obsidian open<CR>',      desc = 'Open in Obsidian' },
      {
        '<leader>ob',
        function()
          local path = vim.fn.expand('%:p')
          if path == '' then
            return
          end
          local Note = require('obsidian.note')
          local ok, note = pcall(function()
            return Note.from_file(path)
          end)
          if not ok or not note then
            return
          end
          local matches = note:backlinks({})
          if not matches or #matches == 0 then
            vim.notify('No backlinks found', vim.log.levels.INFO)
            return
          end
          local items = vim
              .iter(matches)
              :map(function(m)
                return {
                  filename = tostring(m.path),
                  lnum = m.line,
                  col = (m.start or 0) + 1,
                  text = m.text,
                }
              end)
              :totable()
          vim.fn.setqflist(items, 'r')
          vim.cmd('copen')
        end,
        desc = 'Backlinks to quickfix',
      },
      { '<leader>oB', '<cmd>Obsidian backlinks<CR>', desc = 'Backlinks' },
      { '<leader>od', '<cmd>Obsidian dailies<CR>',   desc = 'Daily notes' },
      { '<leader>oL', '<cmd>Obsidian links<CR>',     desc = 'Links in note' },
      {
        '<leader>ol',
        function()
          local path = vim.fn.expand('%:p')
          if path == '' then
            return
          end
          local Note = require('obsidian.note')
          local ok, note = pcall(function()
            return Note.from_file(path)
          end)
          if not ok or not note then
            return
          end
          local matches = note:links()
          if not matches or #matches == 0 then
            vim.notify('No links found', vim.log.levels.INFO)
            return
          end
          local items = vim
              .iter(matches)
              :map(function(m)
                return {
                  filename = path,
                  lnum = m.line,
                  col = (m.start or 0) + 1,
                  text = m.link,
                }
              end)
              :totable()
          vim.fn.setqflist(items, 'r')
          vim.cmd('copen')
        end,
        desc = 'Links to quickfix',
      },
      { '<leader>ch',  '<cmd>Obsidian check<CR>',  desc = 'Health check' },
      { '<leader>oR',  '<cmd>Obsidian rename<CR>', desc = 'Rename note' },
      { '<leader>toc', '<cmd>Obsidian toc<CR>',    desc = 'Table of contents' },
      { '<leader>n',   create_note_from_selection, mode = 'v',                desc = 'Create note from selection' },
    }
  end,
  config = function()
    local vault = state.env.notes.OBSIDIAN_VAULT
    local inbox_subdir = state.env.notes.OBSIDIAN_INBOX:gsub(vault .. '/', '')

    local Path = require('obsidian.path')

    require('obsidian').setup({
      legacy_commands = false,
      workspaces = {
        { name = 'garden', path = vault },
        { name = 'work',   path = state.env.notes.OBSIDIAN_VAULT_WORK },
      },
      notes_subdir = inbox_subdir,
      new_notes_location = 'notes_subdir',
      daily_notes = {
        folder = 'daily',
      },
      templates = {
        folder = 'templates',
        date_format = '%F',
        time_format = '%H:%M',
        substitutions = {},
      },
      -- note = {
      --   template = 'Empty.md',
      -- },
      frontmatter = {
        enabled = false,
      },
      attachments = {
        folder = 'attachments',
        confirm_img_paste = true,
      },
      ui = {
        enable = true,
        enabled = true,
        ignore_conceal_warn = false,
        update_debounce = 200,
        max_file_length = 5000,
        bullets = { char = '•', hl_group = 'ObsidianBullet' },
        external_link_icon = { char = '', hl_group = 'ObsidianExtLinkIcon' },
        reference_text = { hl_group = 'ObsidianRefText' },
        highlight_text = { hl_group = 'ObsidianHighlightText' },
        tags = { hl_group = 'ObsidianTag' },
        block_ids = { hl_group = 'ObsidianBlockID' },
        hl_groups = {
          ObsidianTodo = { bold = true, fg = '#f78c6c' },
          ObsidianDone = { bold = true, fg = '#89ddff' },
          ObsidianRightArrow = { bold = true, fg = '#f78c6c' },
          ObsidianTilde = { bold = true, fg = '#ff5370' },
          ObsidianImportant = { bold = true, fg = '#d73128' },
          ObsidianBullet = { bold = true, fg = '#89ddff' },
          ObsidianRefText = { underline = true, fg = '#c792ea' },
          ObsidianExtLinkIcon = { fg = '#c792ea' },
          ObsidianTag = { italic = true, fg = '#89ddff' },
          ObsidianBlockID = { italic = true, fg = '#89ddff' },
          ObsidianHighlightText = { bg = '#75662e' },
        },
        -- checkboxes = { },
      },
      picker = {
        name = 'fzf-lua',
        note_mappings = {
          new = '<C-x>',
          insert_link = '<C-l>',
        },
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
    })

    -- Fix the work workspace root to the actual vault directory
    -- (path is PRIVATE_NOTES for workspace detection, but the vault root
    -- must be OBSIDIAN_VAULT_WORK so operations like daily notes,
    -- templates, and LSP use the correct directory)
    for _, ws in ipairs(Obsidian.workspaces) do
      if ws.name == 'work' then
        ws.root = Path.new(state.env.notes.OBSIDIAN_VAULT_WORK):resolve({ strict = true })
        if Obsidian.workspace and Obsidian.workspace.name == 'work' then
          Obsidian.dir = ws.root
        end
        break
      end
    end

    vim.api.nvim_set_hl(0, 'ObsidianRefText', {
      bg = 'none',
      fg = state.colors.links or state.colors.purple or state.colors.primary,
      underline = true,
      bold = true,
    })

    vim.schedule(function()
      if lib.cwd.matches({ 'work' }) then
        Obsidian.workspace.set('work')
      end
    end)
  end,
}
