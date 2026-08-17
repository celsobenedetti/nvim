-- lazily grab fzf-lua so requiring this module doesn't force-load it
local function fzf()
  return require('fzf-lua')
end

local tab = require('lib.tab')

--- Open a CodeDiff of `commit` against its parent and name the tab.
---@param commit string short/long sha
---@param text? string full entry text, sniffed for a `#PR` number
local function open_codediff(commit, text)
  if not commit or commit == '' then
    return
  end

  vim.fn.setreg('+', commit) -- copy sha to clipboard

  local get_parent_commit = { 'git', 'rev-parse', '--short', commit .. '^' }
  local result = vim.system(get_parent_commit):wait()
  if result.code ~= 0 then
    vim.notify('Cannot find parent (Root commit?)', vim.log.levels.WARN)
    return
  end

  local parent = vim.trim(result.stdout):match('[a-f0-9]+')
  Snacks.notify.info('git show ' .. commit, { title = 'Git', icon = '', style = 'fancy' })
  vim.cmd(string.format('CodeDiff %s %s', parent, commit))

  local tabname = vim.g.icons.git.commit .. commit
  local pr_number = text and text:match('#(%d+)')
  if pr_number ~= nil and pr_number ~= '' then
    tabname = string.format('%s #%s', tabname, pr_number)
  end
  tab.set_next_name(tabname)
end

--- Snacks picker `confirm` (still used by git_pickaxe).
local function walk_in_codediff(picker, item)
  picker:close()
  if item.commit then
    open_codediff(item.commit, item.text)
  end
end

--- fzf-lua action: the commit sha is the first token of the entry (git log /
--- bcommits / blame all lead with it); strip ANSI and a blame boundary `^`.
local function fzf_codediff(selected)
  local line = selected and selected[1]
  if not line then
    return
  end
  line = fzf().utils.strip_ansi_coloring(line)
  local commit = (line:match('%S+') or ''):gsub('^%^', '')
  open_codediff(commit, line)
end

--- git_commits/git_bcommits/git_blame with our CodeDiff action bound to <CR>;
--- other default actions (e.g. ctrl-y = yank sha) survive the merge.
---@param picker 'git_commits'|'git_bcommits'|'git_blame'
---@param o? table extra fzf-lua opts
local function codediff_picker(picker, o)
  return function()
    fzf()[picker](vim.tbl_deep_extend('force', { actions = { enter = fzf_codediff } }, o or {}))
  end
end

local function git_pickaxe(opts)
  opts = opts or {}
  local is_global = opts.global or false
  local current_file = vim.api.nvim_buf_get_name(0)
  -- Force global if current buffer is invalid
  if not is_global and (current_file == '' or current_file == nil) then
    vim.notify('Buffer is not a file, switching to global search', vim.log.levels.WARN)
    is_global = true
  end

  local title_scope = is_global and 'Global' or vim.fn.fnamemodify(current_file, ':t')
  vim.ui.input({ prompt = 'Git Search (-G) in ' .. title_scope .. ': ' }, function(query)
    if not query or query == '' then
      return
    end

    -- set keyword highlight within Snacks.picker
    vim.fn.setreg('/', query)
    local old_hl = vim.opt.hlsearch
    vim.opt.hlsearch = true

    local args = {
      'log',
      '-G' .. query,
      '-i',
      '--pretty=format:%C(yellow)%h%Creset %s %C(green)(%cr)%Creset %C(blue)<%an>%Creset',
      '--abbrev-commit',
      '--date=short',
    }

    if not is_global then
      table.insert(args, '--')
      table.insert(args, current_file)
    end

    Snacks.picker({
      title = 'Git Log: "' .. query .. '" (' .. title_scope .. ')',
      finder = 'proc',
      cmd = 'git',
      args = args,
      layout = 'ivy_split',

      transform = function(item)
        local clean_text = item.text:gsub('\27%[[0-9;]*m', '')
        local hash = clean_text:match('^%S+')
        if hash then
          item.commit = hash
          if not is_global then
            item.file = current_file
          end
        end
        return item
      end,

      preview = 'git_show',
      confirm = walk_in_codediff,
      format = 'text',

      on_close = function()
        -- remove keyword highlight
        vim.opt.hlsearch = old_hl
        vim.cmd('noh')
      end,
    })
  end)
end

--- runs command and renames tab
---@param cmd string
local function codefiff_cmd(cmd)
  return function()
    vim.cmd(cmd)
  end
end

--- codediff.nvim's `gf` (`open_in_prev_tab`) always targets the tab
--- immediately left of the diff tab (tabs[current_index - 1]). We want it to
--- always land in the *first* tab instead, since that's the "home" tab our
--- diff-launching workflow returns to. The plugin hardcodes this action, so
--- we monkeypatch it here rather than reimplementing the keymap wiring.
local function patch_gf_to_open_in_first_tab()
  local ok, panes = pcall(require, 'codediff.ui.view.actions.panes')
  if not ok then
    return
  end
  local lifecycle = require('codediff.ui.lifecycle')
  local cfg = require('codediff.config')

  local function get_explorer_target_file(explorer, session)
    local node = explorer.tree and explorer.tree:get_node()
    local data = node and node.data
    if not data or data.type == 'group' or data.type == 'directory' or not data.path or data.path == '' then
      return nil
    end
    local git_root = data.git_root or explorer.git_root or session.git_root
    if not git_root or git_root == '' then
      return nil
    end
    return vim.fs.joinpath(git_root, data.path)
  end

  panes.open_in_prev_tab = function(ctx)
    local session = lifecycle.get_session(ctx.tabpage)
    if not session then
      return
    end

    local current_buf = vim.api.nvim_get_current_buf()
    local side = nil
    if current_buf == ctx.original_bufnr then
      side = 'original'
    elseif current_buf == ctx.modified_bufnr then
      side = 'modified'
    end

    local explorer = lifecycle.get_explorer(ctx.tabpage)
    local is_explorer_buf = explorer and explorer.bufnr and current_buf == explorer.bufnr

    if not side and not is_explorer_buf then
      return
    end

    local is_virtual = (side == 'original' and lifecycle.is_original_virtual(ctx.tabpage))
      or (side == 'modified' and lifecycle.is_modified_virtual(ctx.tabpage))

    local target_file
    if is_explorer_buf then
      target_file = get_explorer_target_file(explorer, session)
      if not target_file then
        return
      end
    elseif is_virtual then
      local original, modified = lifecycle.get_paths(ctx.tabpage)
      local ref = side == 'original' and original or modified
      if not ref or ref.absolute == '' then
        vim.notify('Buffer has no associated file path', vim.log.levels.WARN)
        return
      end
      target_file = ref.absolute
    else
      target_file = vim.api.nvim_buf_get_name(current_buf)
      if target_file == '' then
        vim.notify('Buffer has no name; cannot open in first tab', vim.log.levels.WARN)
        return
      end
    end

    local cursor = side and vim.api.nvim_win_get_cursor(0) or nil
    local current_tab = vim.api.nvim_get_current_tabpage()
    local tabs = vim.api.nvim_list_tabpages()

    local current_index = nil
    for i, t in ipairs(tabs) do
      if t == current_tab then
        current_index = i
        break
      end
    end

    -- Only deviation from upstream: always target the first tab rather than
    -- the one immediately preceding the diff tab.
    local target_tab
    if current_index and current_index > 1 then
      target_tab = tabs[1]
    else
      vim.cmd('tabnew')
      target_tab = vim.api.nvim_get_current_tabpage()
      vim.cmd('tabmove 0')
    end

    if vim.api.nvim_get_current_tabpage() ~= target_tab then
      vim.api.nvim_set_current_tabpage(target_tab)
    end

    local target_win = vim.api.nvim_get_current_win()
    if not vim.api.nvim_win_is_valid(target_win) then
      vim.notify('No valid window in target tab to open buffer', vim.log.levels.ERROR)
      return
    end

    local edit_ok, err
    if is_virtual or is_explorer_buf then
      edit_ok, err = pcall(vim.cmd, 'edit ' .. vim.fn.fnameescape(target_file))
    else
      edit_ok, err = pcall(vim.api.nvim_win_set_buf, target_win, current_buf)
    end
    if not edit_ok then
      vim.notify('Failed to open buffer in first tab: ' .. err, vim.log.levels.ERROR)
      return
    end

    if cursor then
      pcall(vim.api.nvim_win_set_cursor, target_win, cursor)
    end

    if cfg.options.keymaps.view.close_on_open_in_prev_tab then
      if vim.api.nvim_tabpage_is_valid(current_tab) then
        vim.api.nvim_set_current_tabpage(current_tab)
        vim.cmd('tabclose')
      end
    end
  end
end

return {
  {
    'esmuellert/codediff.nvim',
    dependencies = { 'MunifTanjim/nui.nvim' },
    cmd = 'CodeDiff',

    keys = {
      -- stylua: ignore start
      { '<leader>gl', codediff_picker('git_commits'), desc = 'pickaxe: find_git_log', },
      { '<leader>sc', codediff_picker('git_commits'), desc = 'git: search commit', },
      { '<leader>gf', codediff_picker('git_bcommits', { follow = true }), desc = 'pickaxe: find_git_log_file', },
      { '<leader>gL', codefiff_cmd("CodeDiff history"), desc = 'codediff: git log', },
      { '<leader>gF', codefiff_cmd("CodeDiff history %"), desc = 'codediff: git log file', },
      { '<leader>gb', codediff_picker('git_blame'), desc = 'fzf: Git Blame Line', },
      { '<leader>hs', function() git_pickaxe({ global = false }) end, desc = 'pickaxe: Git Search (Buffer)', },
      { '<leader>hS', function() git_pickaxe({ global = true }) end, desc = 'pickaxe: Git Search (Global)', },
      -- stylua: ignore end
    },
    config = function(_, opts)
      opts = opts or {}
      opts.highlights = vim.tbl_deep_extend('force', opts.highlights or {}, {
        -- Character-level: accepts highlight group names or hex colors
        -- If specified, these override char_brightness calculation
        char_insert = nil, -- Character-level insertions (nil = auto-derive)
        char_delete = nil, -- Character-level deletions (nil = auto-derive)
        char_brightness = nil, -- Auto-adjust based on your colorscheme
      })

      require('codediff').setup(vim.tbl_deep_extend('force', opts, {
        -- Highlight configuration

        -- Diff view behavior
        diff = {
          disable_inlay_hints = true, -- Disable inlay hints in diff windows for cleaner view
          max_computation_time_ms = 5000, -- Maximum time for diff computation (VSCode default)
          layout = 'inline',
        },

        -- Explorer (file tree) configuration
        explorer = {
          view_mode = 'tree', -- Show directory tree instead of flat list
          flatten_dirs = true, -- Compress single-child directory chains
          indent_markers = true, -- Show tree connectors (│, ├, └)
        },

        -- Keymaps in diff view
        keymaps = {
          view = {
            quit = 'q', -- Close diff tab
            toggle_explorer = '<leader>b', -- Toggle explorer visibility (explorer mode only)
            next_hunk = ']g', -- Jump to next change
            prev_hunk = '[g', -- Jump to previous change
            next_file = ']b', -- Next file in explorer mode
            prev_file = '[b', -- Previous file in explorer mode
            open_in_prev_tab = 'gf',
          },
          explorer = {
            select = '<CR>', -- Open diff for selected file
            hover = 'K', -- Show file diff preview
            refresh = 'R', -- Refresh git status
          },
        },
      }))

      patch_gf_to_open_in_first_tab()

      vim.cmd.cnoreabbrev(('%s %s'):format('codediff', 'CodeDiff'))

      vim.api.nvim_create_autocmd('User', {
        pattern = 'CodeDiffOpen',
        group = vim.api.nvim_create_augroup('celso_codediff_fold', { clear = true }),
        callback = function(ev)
          local data = ev.data
          if not data or not data.tabpage then
            return
          end
          if not vim.api.nvim_tabpage_is_valid(data.tabpage) then
            return
          end
          for _, win in ipairs(vim.api.nvim_tabpage_list_wins(data.tabpage)) do
            vim.wo[win].foldenable = false
          end
        end,
      })

      vim.api.nvim_create_autocmd('BufReadCmd', {
        group = vim.api.nvim_create_augroup('celso_codefiff', { clear = true }),
        pattern = 'vscodediff:///*',
        callback = function()
          tab.rename(' diff')
        end,
      })
    end,
  },
}
