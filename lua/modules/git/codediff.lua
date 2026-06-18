local function walk_in_codediff(picker, item)
  picker:close()
  if not item.commit then
    return
  end

  vim.fn.setreg('+', item.commit) -- copy sha to clipboard

  local get_parent_commit = { 'git', 'rev-parse', '--short', item.commit .. '^' }
  local result = vim.system(get_parent_commit):wait()
  if result.code ~= 0 then
    vim.notify('Cannot find parent (Root commit?)', vim.log.levels.WARN)
    return
  end

  local parent = vim.trim(result.stdout):match('[a-f0-9]+')
  Snacks.notify.info('git show ' .. item.commit, { title = 'Git', icon = '', style = 'fancy' })
  vim.cmd(string.format('CodeDiff %s %s', parent, item.commit))
  vim.g.tabname = vim.g.icons.git.commit .. item.commit

  local pr_number = item.text:match('#(%d+)')
  if pr_number ~= nil and pr_number ~= '' then
    vim.g.tabname = string.format('%s #%s', vim.g.tabname, pr_number)
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

return {
  {
    'esmuellert/codediff.nvim',
    dependencies = { 'MunifTanjim/nui.nvim' },
    cmd = 'CodeDiff',

    keys = {
      -- stylua: ignore start
      { '<leader>gl', function() Snacks.picker.git_log({ confirm = walk_in_codediff, layout="ivy_split" }) end, desc = 'pickaxe: find_git_log', },
      { '<leader>sc', function() Snacks.picker.git_log({ confirm = walk_in_codediff, layout="ivy_split" }) end, desc = 'git: search commit', },
      { '<leader>gf', function() Snacks.picker.git_log_file({ confirm = walk_in_codediff, layout="ivy_split", title="git log -- ".. vim.fn.expand("%:.") }) end, desc = 'pickaxe: find_git_log_file', },
      { '<leader>gL', codefiff_cmd("CodeDiff history"), desc = 'codediff: git log', },
      { '<leader>gF', codefiff_cmd("CodeDiff history %"), desc = 'codediff: git log file', },
      { '<leader>gb', function() Snacks.picker.git_log_line({confirm = walk_in_codediff}) end, { desc = 'snacks: Git Blame Line' }, },
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

      vim.cmd.cnoreabbrev(('%s %s'):format('codediff', 'CodeDiff'))

      vim.api.nvim_create_autocmd('User', {
        pattern = 'CodeDiffOpen',
        group = vim.api.nvim_create_augroup('celso_codediff_fold', { clear = true }),
        callback = function(ev)
          local data = ev.data
          if not data or not data.tabpage then return end
          if not vim.api.nvim_tabpage_is_valid(data.tabpage) then return end
          for _, win in ipairs(vim.api.nvim_tabpage_list_wins(data.tabpage)) do
            vim.wo[win].foldenable = false
          end
        end,
      })

      vim.api.nvim_create_autocmd('BufReadCmd', {
        group = vim.api.nvim_create_augroup('celso_codefiff', { clear = true }),
        pattern = 'vscodediff:///*',
        callback = function()
          vim.g.fn.rename_tab(' diff')
        end,
      })
    end,
  },
}
