local function walk_in_codediff(picker, item)
  picker:close()
  if item.commit then
    local current_commit = item.commit

    vim.fn.setreg('+', current_commit)
    vim.notify('Copied: ' .. current_commit)
    -- get parent / previous commit
    local parent_commit = vim.trim(vim.fn.system('git rev-parse --short ' .. current_commit .. '^'))
    parent_commit = parent_commit:match('[a-f0-9]+')
    -- Check if command failed (e.g., Initial commit has no parent)
    if vim.v.shell_error ~= 0 then
      vim.notify('Cannot find parent (Root commit?)', vim.log.levels.WARN)
      parent_commit = ''
    end
    local cmd = string.format('CodeDiff %s %s', parent_commit, current_commit)
    vim.notify('Diffing: ' .. parent_commit .. ' -> ' .. current_commit)
    vim.cmd(cmd)
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

return {
  {
    'esmuellert/vscode-diff.nvim',
    dependencies = { 'MunifTanjim/nui.nvim' },
    cmd = 'CodeDiff',
    config = function()
      require('vscode-diff').setup({
        -- Highlight configuration
        highlights = {
          -- Line-level: accepts highlight group names or hex colors (e.g., "#2ea043")
          line_insert = 'DiffAdd', -- Line-level insertions
          line_delete = 'DiffDelete', -- Line-level deletions

          -- Character-level: accepts highlight group names or hex colors
          -- If specified, these override char_brightness calculation
          char_insert = nil, -- Character-level insertions (nil = auto-derive)
          char_delete = nil, -- Character-level deletions (nil = auto-derive)

          -- Brightness multiplier (only used when char_insert/char_delete are nil)
          -- nil = auto-detect based on background (1.4 for dark, 0.92 for light)
          char_brightness = nil, -- Auto-adjust based on your colorscheme
        },

        -- Diff view behavior
        diff = {
          disable_inlay_hints = true, -- Disable inlay hints in diff windows for cleaner view
          max_computation_time_ms = 5000, -- Maximum time for diff computation (VSCode default)
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
          },
          explorer = {
            select = '<CR>', -- Open diff for selected file
            hover = 'K', -- Show file diff preview
            refresh = 'R', -- Refresh git status
          },
        },
      })

      vim.api.nvim_create_autocmd('BufReadCmd', {
        group = vim.api.nvim_create_augroup('celso_codefiff', { clear = true }),
        pattern = 'vscodediff:///*',
        callback = function()
          vim.g.fn.rename_tab(' diff')
        end,
      })
    end,

    keys = {
      -- stylua: ignore start
      { '<leader>hs', function() git_pickaxe({ global = false }) end, desc = 'pickaxe: Git Search (Buffer)', },
      { '<leader>hS', function() git_pickaxe({ global = true }) end, desc = 'pickaxe: Git Search (Global)', },
      { '<leader>gf', function() Snacks.picker.git_log_file({ confirm = walk_in_codediff }) end, desc = 'pickaxe: find_git_log_file', },
      { '<leader>gl', function() Snacks.picker.git_log({ confirm = walk_in_codediff }) end, desc = 'pickaxe: find_git_log', },
      -- stylua: ignore end
    },
  },
}
