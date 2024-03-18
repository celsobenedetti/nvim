---@diagnostic disable: param-type-mismatch
local spec = {

  {
    'folke/twilight.nvim',
    config = function()
      require('twilight').setup {
        context = 20, -- amount of lines we will try to show around the current line
      }
    end,
    ft = { 'markdown' },
    keys = { { '<leader>tw', ':Twilight<CR>' } },
  },

  {
    'zk-org/zk-nvim',
    ft = 'markdown',
    keys = {
      { '<leader>zn', ':ZkNewFromTitleSelection<CR>', mode = 'v' },
      { '<leader>zn', ':ZkNewFromTitleSelection<CR>', mode = 'v' },
      { '<leader>zz', ':ZkNotes<CR>' },
      { '<leader>zb', ':ZkBacklinks<CR>' },
      { '<leader>zt', ':ZkTags<CR>' },
      { '<leader>zm', ':ZkMatch<CR>', mode = 'v' },
      { '<leader>zl', ':ZkLinks<CR>' },
      { '<leader>zL', ':ZkInsertLink<CR>' },
      { '<leader>ch', ':norm @c<CR>', mode = 'v' },
    },
    dependencies = {
      {
        'williamboman/mason.nvim',
        opts = function(_, opts)
          if type(opts.ensure_installed) == 'table' then
            vim.list_extend(opts.ensure_installed, { 'zk' })
          end
        end,
      },
    },

    config = function()
      require('zk').setup {
        picker = 'telescope',
      }

      vim.keymap.set('i', '<c-b>', function()
        vim.api.nvim_feedkeys(Keys '****<Esc>hha', 'n', true)
      end, { desc = 'Add bold tags for insert mode in bold' })

      vim.keymap.set('i', '<c-t>', function()
        vim.api.nvim_feedkeys(Keys '~~~~<Esc>hha', 'n', true)
      end, { desc = 'Add Strikeghrough italic tags for insert mode in bold' })
    end,
  },

  {
    'epwalsh/obsidian.nvim',
    -- commit = "06154ec6f2964632d53c8fea9f0c175f31357192",
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
      { '<leader>ch', ':norm @c<CR>', mode = 'v' },
    },
    cond = function()
      local path = vim.fn.expand '%:p:h'
      local is_notes = string.match(path, 'notes')
      local is_templates = string.match(path, 'templates')
      return is_notes and not is_templates
    end,
    opts = function(_, opts)
      opts.new_notes_location = 'notes_subdir'
      opts.workspaces = {
        {
          name = 'notes',
          path = '~/Documents/notes',
          overrides = {
            notes_subdir = '0-inbox',
          },
        },
      }
      opts.ui = {
        checkboxes = {
          [' '] = { char = '󰄱', hl_group = 'ObsidianTodo' },
          ['>'] = { char = '', hl_group = 'ObsidianRightArrow' },
          ['~'] = { char = 'x', hl_group = 'ObsidianTilde' },
          ['x'] = { char = '✔', hl_group = 'ObsidianDone' },
        },
      }
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

vim.api.nvim_create_autocmd({ 'VimEnter' }, {
  pattern = '*.md',
  callback = function()
    vim.api.nvim_feedkeys(Keys 'gg/#<CR>', 'n', true)
    vim.api.nvim_feedkeys(Keys ':nohlsearch<CR>', 'n', true)
    vim.cmd.colorscheme(vim.g.pretty_colorscheme)
    require('twilight').enable()
  end,
  group = vim.api.nvim_create_augroup('MarkdownGroup', { clear = true }),
  desc = 'Run on Markdown file when first entering Neovim',
})

vim.api.nvim_create_autocmd({ 'VimEnter' }, {
  pattern = 'new_note',
  callback = function()
    vim.cmd.colorscheme(vim.g.pretty_colorscheme)
    vim.api.nvim_feedkeys(Keys 'ggi<BS><BS><BS>', 'n', true)
  end,
  group = vim.api.nvim_create_augroup('NewNoteGroup', { clear = true }),
  desc = 'Run when entering new_note files',
})

return spec
