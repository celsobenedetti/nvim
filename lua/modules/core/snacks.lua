local cwd = require('lib.cwd')

local function dotfiles()
  Snacks.picker.files({
    dirs = { '~/.dotfiles', '~/.config/nvim' },
    title = 'dotfiles',
    hidden = true,
    layout = 'select',
  })
end

local function cd()
  Snacks.picker.zoxide({ confirm = { 'cd', 'lcd', 'close' }, title = 'cd (zoxide)' })
end

local function workspace()
  Snacks.picker.zoxide({
    confirm = {
      function(_, item)
        vim.cmd('tabnew')
        if item.file and item.file ~= '' then
          vim.g.fn.rename_tab(vim.fs.basename(item.file))
        end
      end,
      'lcd',
      'close',
    },
    title = 'workspace (zoxide)',
  })
end

return {
  'folke/snacks.nvim',
  lazy = false,
  ---@type snacks.Config
  opts = {
    terminal = { enabled = true },
    words = { enabled = true },
    notify = { enabled = true },
    indent = { enabled = true },
    input = { enabled = false },

    bigfile = {
      enabled = true,
      notify = true, -- show notification when big file detected
      size = 1.5 * 1024 * 1024, -- 1.5MB
      line_length = 1000, -- average line length (useful for minified files)
      -- Enable or disable features when big file detected
      ---@param ctx {buf: number, ft:string}
      setup = function(ctx)
        if vim.fn.exists(':NoMatchParen') ~= 0 then
          vim.cmd([[NoMatchParen]])
        end
        Snacks.util.wo(0, { foldmethod = 'manual', statuscolumn = '', conceallevel = 0 })
        vim.b.completion = false
        vim.b.minianimate_disable = true
        vim.b.minihipatterns_disable = true
        vim.b.snacks_indent = false
        vim.schedule(function()
          if vim.api.nvim_buf_is_valid(ctx.buf) then
            vim.bo[ctx.buf].syntax = ctx.ft
          end
        end)
      end,
    },
    notifier = {
      top_down = false,
      enabled = true,
      -- margin = {
      --   top = 0,
      --   right = 100, -- A large value to push it to the left edge
      --   bottom = 0,
      -- },
      filter = function(notification)
        local ignore = {
          'File is too large to send to server', -- thank you supermaven, please stfu
          'Request textDocument/diagnostic failed with message: No ESLint configuration found in', -- err when eslint is not available
          'No results found for.*buffers', -- Snacks.picker.buffers when there are no results
        }
        for _, s in ipairs(ignore) do
          if notification.msg:find(s) then
            return false
          end
        end
        return true
      end,
    },
    lazygit = {
      -- theme = { selectedLineBgColor = { bg = 'CursorLine' } },
      win = { width = 0, height = 0 },
    },
    picker = {
      enabled = true,
      exclude = vim.g.ignore.grep,
      layout = 'ivy_split',
      win = {
        input = {
          keys = {
            ['<c-x>'] = { 'bufdelete', mode = { 'n', 'i' } },
            ['<a-s>'] = { 'flash', mode = { 'n', 'i' } },
            ['<c-y>'] = { 'yank', mode = { 'n', 'i' } },
            ['<c-l>'] = { 'yank', mode = { 'n', 'i' } }, -- TODO: this should actually insert the text to buffer
            ['<a-q>'] = { 'qflist', mode = { 'n', 'i' } },
            -- ['s'] = { 'flash' },
          },
        },
      },
      layouts = {
        select = {
          hidden = { 'preview' },
          layout = {
            backdrop = false,
            width = 0.5,
            min_width = 80,
            max_width = 100,
            height = 0.4,
            min_height = 2,
            box = 'vertical',
            border = true,
            title = '{title}',
            title_pos = 'center',
            { win = 'input', height = 1, border = 'bottom' },
            { win = 'list', border = 'none' },
            -- { win = 'preview', title = '{preview}', height = 0.4, border = 'top' },
          },
        },
      },

      -- Scoped to the `overseer_template` select picker (OverseerRun). Adds a
      -- key to launch the highlighted command in a `tmux new-window` instead of
      -- running it through an overseer task.
      kinds = {
        overseer_template = {
          win = {
            input = {
              keys = {
                ['<c-t>'] = { 'run_in_tmux', mode = { 'n', 'i' } },
              },
            },
          },
          actions = {
            run_in_tmux = function(picker, item)
              local tmpl = item and item.item
              if not tmpl then
                return
              end
              picker:close()
              -- Build the task (resolving cmd/cwd/env) but don't start it.
              require('overseer').run_task({ name = tmpl.name, autostart = false }, function(task, err)
                if not task then
                  Snacks.notify.error('Overseer: ' .. (err or 'could not build task'))
                  return
                end
                local cmd = task.cmd
                if type(cmd) == 'table' then
                  cmd = table.concat(cmd, ' ')
                end
                local args = { 'tmux', 'new-window', '-c', task.cwd or vim.fn.getcwd() }
                for k, v in pairs(task.env or {}) do
                  vim.list_extend(args, { '-e', string.format('%s=%s', k, v) })
                end
                table.insert(args, cmd)
                task:dispose(true) -- drop the unstarted task from the task list
                vim.system(args, { text = true }, function(out)
                  if out.code ~= 0 then
                    vim.schedule(function()
                      Snacks.notify.error('tmux: ' .. (out.stderr ~= '' and out.stderr or 'new-window failed'))
                    end)
                  end
                end)
              end)
            end,
          },
        },
      },

      sources = {
        explorer = {
          auto_close = false,
          ignored = true,
          exclude = vim.g.ignore.explorer,
          win = {
            list = {
              keys = {
                ['Z'] = function()
                  vim.cmd('q')
                end,
                ['d'] = 'safe_delete',
              },
            },
          },
          actions = {
            safe_delete = function(picker)
              local selected = picker:selected({ fallback = true })
              local is_root = vim.iter(selected):any(function(s)
                return not s.parent
              end)
              if is_root then
                Snacks.notify.warn("Let's not delete root please")
                return
              end
              picker:action('explorer_del')
            end,
          },
        },
      },

      actions = {
        flash = function(picker)
          require('flash').jump({
            pattern = '^',
            label = { after = { 0, 0 } },
            search = {
              mode = 'search',
              exclude = {
                function(win)
                  return vim.bo[vim.api.nvim_win_get_buf(win)].filetype ~= 'snacks_picker_list'
                end,
              },
            },
            action = function(match)
              local idx = picker.list:row2idx(match.pos[1])
              picker.list:_move(idx, true, true)
            end,
          })
        end,
      },
    },
  },
  keys = {

    -- {
    --   '<C-p>',
    --   function()
    --     Snacks.picker.smart({
    --       layout = 'select',
    --       title = '',
    --       hidden = cwd.cwd():find('dotfiles'),
    --     })
    --   end,
    --   desc = 'snacks: Smart picker',
    --   mode = { 'n' },
    -- },
    -- stylua: ignore start
    -- TODO: figure out cwd in terminal, if opening file with different cwd from root
    -- keymap won't work inside terminal, opening a second terminal instead of toggling the first
    -- { '<c-/>', function() Snacks.terminal.toggle() end, desc = 'snacks: terminal toggle', mode = { 'n', 't' }, },
    { '<leader>no', function() Snacks.picker.notifications() end, desc = 'snacks: notification history', },
    { '<leader>dd', function() Snacks.bufdelete() end, desc = 'snacks: delete buffer', },
    { '<leader>dot', dotfiles, desc = 'snacks: search dotfiles', },
    { '<leader>cR', function() Snacks.rename.rename_file() end, desc = 'snacks: Rename File', },
    { '<leader>lgl', function() Snacks.lazygit.log() end, desc = 'snacks: Lazygit Log (cwd)', },
    { '<leader>fE', function() Snacks.explorer { cwd = cwd.root() } end, desc = 'snacks: Explorer Snacks (root dir)', },
    { '<leader>dab', function() Snacks.bufdelete.all() end, desc = 'snacks: delete all buffers', },
    { '<leader>cd', cd, desc = 'snacks: zoxide (cd)', },
    { '<leader>ws', workspace, desc = 'snacks: workspace (zoxide)', },

    { '♣', Explorer, desc = 'snacks: explorer', }, -- C-S-E set in terminal
    { '<leader>fe', function()Snacks.explorer()end, desc = 'snacks: explorer (fe)', },


    -- -- git
    { '<leader>fp', function() Snacks.picker.projects() end, desc = 'snacks: Projects', },
    { '<leader>gD', function() Snacks.picker.git_diff { base = 'origin', group = true } end, desc = 'snacks: Git Diff (origin)', },
    -- { '<leader>gi', function() Snacks.picker.gh_issue() end, desc = 'snacks: GitHub Issues (open)', },
    -- { '<leader>gI', function() Snacks.picker.gh_issue { state = 'all' } end, desc = 'snacks: GitHub Issues (all)', },
    { '<leader>gp', function() Snacks.picker.gh_pr() end, desc = 'snacks: GitHub Pull Requests (open)', },
    { '<leader>gP', function() Snacks.picker.gh_pr { state = 'all' } end, desc = 'snacks: GitHub Pull Requests (all)', },
    -- -- Grep
    { '<leader>sla', function() Snacks.picker.lazy() end, desc = 'snacks: Search for Plugin Spec', },
    -- search
    { '<leader>si', function() Snacks.picker.icons() end, desc = 'snacks: Icons', },


    { '<leader>gg', function() Snacks.lazygit { cwd = cwd.root() } end, desc = 'snacks: Lazygit (Root Dir)', },
    { '<leader>gG', function() Snacks.lazygit() end, desc = 'snacks: Lazygit (cwd)', },
    -- lsp
    { ']]', function() Snacks.words.jump(vim.v.count1) end, desc = 'snacks: Next Reference', },
    { '[[', function() Snacks.words.jump(-vim.v.count1) end, desc = 'snacks: Prev Reference', },
    -- TODO: decide which of these is good
    -- { 'gb', function() Snacks.picker.git_log_line() end, { desc = 'snacks: Git Blame Line' }, },
    { 'gL', function() Snacks.picker.git_log_line() end, { desc = 'Git Blame Line' }, },
    { 'gB', function() Snacks.gitbrowse();  end, { desc = 'snacks: Git Browse (open)' }, },
    { 'gY', function()
      Snacks.gitbrowse { open = function(url) vim.fn.setreg('+', url) end, notify = false, }
      Snacks.notify('Copied permalink to clipboard: ' .. vim.fn.getreg('+'))
    end, { desc = 'snacks: Git Browse (copy)', mode = { 'n', 'x' } }, },

    -- stylua: ignore end
  },
}
