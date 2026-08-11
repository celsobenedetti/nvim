-- lazily grab fzf-lua so requiring this (lazy=false) module doesn't force-load it
local function fzf_lua()
  return require('fzf-lua')
end

-- Mimics the snacks `:e` picker layout (see snacks.lua): anchored bottom-left,
-- no border/backdrop chrome, results growing upward from the prompt line.
-- fzf-lua already defaults to `--layout=reverse` (list grows up), so this only
-- needs to set window geometry.
--
-- This is a pseudo-profile, not a real fzf-lua `profile` (those can only be a
-- string like `profile = 'ivy'`): fzf-lua resolves them via `dofile` against
-- its own plugin directory (see fzf-lua/utils.lua load_profiles), so a
-- user-defined profile would have to live inside the lazy-managed plugin
-- install dir and get wiped on every update. `e(opts)` merges the `:e`
-- winopts with any extra picker opts, mirroring how a real profile is used.
local function e(opts)
  return vim.tbl_extend('force', {
    previewer = false,
    fzf_opts = { ['--layout'] = 'default' },
    winopts = function()
      local cols = vim.o.columns
      return {
        row = 1, -- bottom edge
        col = 0, -- left edge
        width = math.max(0.4, 60 / cols), -- 40% width, at least 60 cols
        height = 0.3,
        border = 'none',
        backdrop = 100, -- fully transparent, i.e. no backdrop
        preview = { hidden = true },
      }
    end,
  }, opts or {})
end

local function notes()
  fzf_lua().files(e({ cwd = '~/notes' }))
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
      'ivy',
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
        require('fzf-lua').files(e({
          -- also list directories alongside files
          cmd = string.gsub(
            [[
            fd --color=never --type f --type l --type d --hidden --follow
          --no-ignore
          --exclude .git
          --exclude node_modules
          --exclude public
          --exclude .vault
          ]],
            '\n',
            ' '
          ),
          actions = (function()
            -- Selecting a directory: `:e $dir`
            -- this is needed becuase fzf-lua's default file actions use bufadd(),
            -- which skips oil's netrw hijack, so directories would open as empty buffers.
            local function dir_or(default_action, splitcmd)
              return function(selected, opts)
                local fzfpath = require('fzf-lua.path')
                if #selected == 1 then
                  local entry = fzfpath.entry_to_file(selected[1], opts, opts._uri)
                  local full = entry.path
                  if full and not fzfpath.is_absolute(full) then
                    full = fzfpath.join({ opts.cwd or opts._cwd or vim.uv.cwd(), full })
                  end
                  if full and vim.fn.isdirectory(full) == 1 then
                    if splitcmd then
                      vim.cmd(splitcmd)
                    end
                    return vim.cmd.e(full)
                  end
                end
                return require('fzf-lua.actions')[default_action](selected, opts)
              end
            end
            return {
              ['enter'] = dir_or('file_edit_or_qf'),
              ['ctrl-s'] = dir_or('file_split', 'split'),
              ['ctrl-v'] = dir_or('file_vsplit', 'vsplit'),
            }
          end)(),
        }))
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
    { '<leader>,', function() fzf_lua().buffers() end, desc = 'fzf: Buffers', },
    { '<leader><leader>', function() fzf_lua().buffers() end, desc = 'fzf: Buffers', },
    { '<leader><', function() fzf_lua().buffers({ show_unlisted = true }) end, desc = 'fzf: Buffers (all)', },
    { '<leader>co', function() fzf_lua().commands({profile = "fzf-vim"}) end, desc = 'fzf: Commands', },
    { '<leader>zo', function() fzf_lua().zoxide() end, desc = 'fzf: zoxide (session)', },
    { '<leader>fF', function() fzf_lua().git_files() end, desc = 'fzf: Find Files (git-files)', },
    { '<leader>rg', function() fzf_lua().live_grep() end, desc = 'fzf: grep', },
    { '<leader>rG', function() fzf_lua().live_grep({ hidden = true, no_ignore = true }) end, desc = 'fzf: grep (all)', },
    { '<leader>sC', function() fzf_lua().command_history({profile = "fzf-vim" }) end, desc = 'fzf: Command History', },
    { 'grs', function() fzf_lua().lsp_references() end, nowait = true, desc = 'fzf: References', },
    { '<leader>fg', function() fzf_lua().git_files() end, desc = 'fzf: Find Files (git-files)', },
    { '<leader>sr', function() fzf_lua().oldfiles() end, desc = 'fzf: Recent', },
    { '<leader>sR', function() fzf_lua().oldfiles({ cwd_only = true }) end, desc = 'fzf: Recent (cwd)', },
    { '<leader>gS', function() fzf_lua().git_stash() end, desc = 'fzf: Git Stash', },
    { '<leader>/', function() fzf_lua().blines() end, desc = 'fzf: Buffer Lines', },
    { '<leader>sB', function() fzf_lua().lines() end, desc = 'fzf: Grep Open Buffers', },
    { '<leader>s"', function() fzf_lua().registers() end, desc = 'fzf: Registers', },
    { '<leader>s/', function() fzf_lua().search_history() end, desc = 'fzf: Search History', },
    { '<leader>sa', function() fzf_lua().autocmds() end, desc = 'fzf: Autocmds', },
    { '<leader>sd', function() fzf_lua().diagnostics_document() end, desc = 'fzf: Buffer Diagnostics', },
    { '<leader>sD', function() fzf_lua().diagnostics_workspace() end, desc = 'fzf: Diagnostics', },
    { '<leader>sh', function() fzf_lua().helptags() end, desc = 'fzf: Help Pages', },
    { '<leader>sj', function() fzf_lua().jumps() end, desc = 'fzf: Jumps', },
    { '<leader>sk', function() fzf_lua().keymaps() end, desc = 'fzf: Keymaps', },
    { '<leader>slo', function() fzf_lua().loclist() end, desc = 'fzf: Location List', },
    { '<leader>sM', function() fzf_lua().manpages() end, desc = 'fzf: Man Pages', },
    { '<leader>sm', function() fzf_lua().marks() end, desc = 'fzf: Marks', },
    { '<leader>pr', function() fzf_lua().resume() end, desc = 'fzf: Resume', },
    { '<leader>sq', function() fzf_lua().quickfix() end, desc = 'fzf: Quickfix List', },
    { '<leader>su', function() fzf_lua().undotree() end, desc = 'fzf: Undotree', },
    { '<leader>dot', function () fzf_lua().files(e({ cwd = '~/.dotfiles' })) end , desc = 'snacks: search dotfiles', },
    -- ui
    { '<leader>uC', function() fzf_lua().colorschemes() end, desc = 'fzf: Colorschemes', },
    { '<leader>sS', function() fzf_lua().lsp_live_workspace_symbols() end, desc = 'fzf: LSP Workspace Symbols', },
    { 'z=', function() fzf_lua().spell_suggest() end, desc = 'fzf: spelling', },
    { '<leader>sH', function() fzf_lua().highlights() end, desc = 'fzf: Highlights', },
    { '<leader>sn', notes, desc = 'snacks: search all notes', },
  },
}
