-- lazily grab fzf-lua so requiring this (lazy=false) module doesn't force-load it
local function fzf()
  return require('fzf-lua')
end

local function notes()
  fzf().files({ cwd = '~/notes' })
end

return {
  'ibhagwan/fzf-lua',
  dependencies = { 'nvim-mini/mini.icons' },
  config = function()
    local fzf = require('fzf-lua')
    ---@module "fzf-lua"
    ---@type fzf-lua.Config|{}
    ---@diagnostic disable: missing-fields
    local opts = {
      'ivy', -- bottom-split UI, closest match to the old Snacks `ivy_split`
      winopts = {
        -- draw a border around the picker (the `ivy` profile is borderless by default)
        border = 'rounded',
        preview = { border = 'rounded' },
      },
      keymap = {
        fzf = {
          ['ctrl-a'] = 'select-all', -- mark every result (then <a-q> to send all to qf)
        },
      },
      -- NOTE: don't set `actions.files` here — it REPLACES fzf-lua's default file
      -- actions (losing `enter`=file_edit_or_qf and the ctrl-s/v/t splits). `alt-q`
      -- → send-to-quickfix is already the built-in default.
    }
    fzf.setup(opts)

    vim.api.nvim_create_autocmd('FileType', {
      pattern = 'fzf',
      callback = function()
        vim.opt_local.number = false
        vim.opt_local.relativenumber = false
      end,
    })
  end,
  keys = {
    {
      '<c-p>',
      function()
        local cols = vim.o.columns
        local max_cols = 120
        require('fzf-lua').files({
          profile = 'fzf-vim',
          previewer = false,
          winopts = {
            height = 0.4,
            width = cols <= max_cols and 1.0 or (max_cols / cols),
          },
        })
      end,
    },

    {
      '<leader>zz',
      function()
        require('fzf-lua').files({
          cwd = '~/notes/obsidian/',
          profile = 'fzf-vim',
          previewer = false,
          winopts = { height = 0.4, width = 0.6 },
        })
      end,
    },


    -- stylua: ignore start
    -- -- find
    { '<leader>,', function() fzf().buffers() end, desc = 'fzf: Buffers', },
    { '<leader><leader>', function() fzf().buffers() end, desc = 'fzf: Buffers', },
    { '<leader><', function() fzf().buffers({ show_unlisted = true }) end, desc = 'fzf: Buffers (all)', },
    { '<leader>co', function() fzf().commands({profile = "fzf-vim"}) end, desc = 'fzf: Commands', },
    { '<leader>zo', function() fzf().zoxide() end, desc = 'fzf: zoxide (session)', },
    { '<leader>fF', function() fzf().git_files() end, desc = 'fzf: Find Files (git-files)', },
    { '<leader>rg', function() fzf().live_grep() end, desc = 'fzf: grep', },
    { '<leader>rG', function() fzf().live_grep({ hidden = true, no_ignore = true }) end, desc = 'fzf: grep (all)', },
    { '<leader>sC', function() fzf().command_history({profile = "fzf-vim" }) end, desc = 'fzf: Command History', },
    { 'grs', function() fzf().lsp_references() end, nowait = true, desc = 'fzf: References', },
    { '<leader>fg', function() fzf().git_files() end, desc = 'fzf: Find Files (git-files)', },
    { '<leader>sr', function() fzf().oldfiles() end, desc = 'fzf: Recent', },
    { '<leader>sR', function() fzf().oldfiles({ cwd_only = true }) end, desc = 'fzf: Recent (cwd)', },
    { '<leader>gS', function() fzf().git_stash() end, desc = 'fzf: Git Stash', },
    { '<leader>/', function() fzf().blines() end, desc = 'fzf: Buffer Lines', },
    { '<leader>sB', function() fzf().lines() end, desc = 'fzf: Grep Open Buffers', },
    { '<leader>s"', function() fzf().registers() end, desc = 'fzf: Registers', },
    { '<leader>s/', function() fzf().search_history() end, desc = 'fzf: Search History', },
    { '<leader>sa', function() fzf().autocmds() end, desc = 'fzf: Autocmds', },
    { '<leader>sd', function() fzf().diagnostics_document() end, desc = 'fzf: Buffer Diagnostics', },
    { '<leader>sD', function() fzf().diagnostics_workspace() end, desc = 'fzf: Diagnostics', },
    { '<leader>sh', function() fzf().helptags() end, desc = 'fzf: Help Pages', },
    { '<leader>sj', function() fzf().jumps() end, desc = 'fzf: Jumps', },
    { '<leader>sk', function() fzf().keymaps() end, desc = 'fzf: Keymaps', },
    { '<leader>slo', function() fzf().loclist() end, desc = 'fzf: Location List', },
    { '<leader>sM', function() fzf().manpages() end, desc = 'fzf: Man Pages', },
    { '<leader>sm', function() fzf().marks() end, desc = 'fzf: Marks', },
    { '<leader>pr', function() fzf().resume() end, desc = 'fzf: Resume', },
    { '<leader>sq', function() fzf().quickfix() end, desc = 'fzf: Quickfix List', },
    { '<leader>su', function() fzf().undotree() end, desc = 'fzf: Undotree', },
    -- ui
    { '<leader>uC', function() fzf().colorschemes() end, desc = 'fzf: Colorschemes', },
    { '<leader>sS', function() fzf().lsp_live_workspace_symbols() end, desc = 'fzf: LSP Workspace Symbols', },
    { 'z=', function() fzf().spell_suggest() end, desc = 'fzf: spelling', },
    { '<leader>sH', function() fzf().highlights() end, desc = 'fzf: Highlights', },
    { '<leader>sn', notes, desc = 'snacks: search all notes', },
  },
}
