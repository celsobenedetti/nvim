---@class LibOverseer
lib.overseer = {
  --- Tasks queued or currently running
  ---@return overseer.Task[]
  get_active_tasks = function()
    if not package.loaded['overseer'] then
      return {}
    end
    return require('overseer').list_tasks({ status = { 'RUNNING', 'PENDING' } })
  end,

  ---@param tasks overseer.TaskDefinition[]
  run_tasks = function(tasks)
    require('lazy').load({ plugins = { 'overseer.nvim' } }) -- ensure overseer
    local overseer = require('overseer')

    for _, task in ipairs(tasks) do
      overseer.register_template({
        name = task.name,
        builder = function()
          return task
        end,
      })
    end

    for _, task in ipairs(tasks) do
      overseer.run_task({ name = task.name, autostart = true })
    end
  end,
}

return {
  {
    'stevearc/overseer.nvim',
    name = 'overseer.nvim',
    lazy = true,
    cmd = {
      'OverseerOpen',
      'OverseerClose',
      'OverseerToggle',
      'OverseerRunCmd',
      'OverseerRun',
      'OverseerInfo',
      'OverseerBuild',
      'OverseerQuickAction',
      'OverseerTaskAction',
      'OverseerClearCache',
    },
    config = function(_, opts)
      local overseer = require('overseer')

      overseer.setup(vim.tbl_deep_extend('error', opts, {
        dap = false,

        task_list = {
          -- min_width = {40, 0.1} means "the greater of 40 columns or 10% of total"
          min_height = { 20, 0.2 },
          keymaps = {
            ['<C-h>'] = false,
            ['<C-j>'] = false,
            ['<C-k>'] = false,
            ['<C-l>'] = false,
          },
        },
        form = {
          win_opts = {
            winblend = 0,
          },
        },
        confirm = {
          win_opts = {
            winblend = 0,
          },
        },
        task_win = {
          win_opts = {
            winblend = 0,
          },
        },
      }))

      local templates = {
        edge_server = {
          test = {
            name = 'gh act -j test',
            builder = function()
              return {
                cmd = { 'act' },
                args = { '-j', 'test' },
                name = 'act -j test',
                cwd = config.dirs.work.edge_server,
                components = { 'default' },
              }
            end,
            desc = 'run CI tests with act',
            condition = {
              dir = config.dirs.work.edge_server,
            },
          },

          lint = {
            name = 'gh act -j lint',
            builder = function()
              return {
                cmd = { 'act' },
                args = { '-j', 'lint' },
                name = 'act -j lint',
                cwd = config.dirs.work.edge_server,
                components = { 'default' },
              }
            end,
            desc = 'run CI lint with act',
            condition = {
              dir = config.dirs.work.edge_server,
            },
          },
        },

        airflow_pipeline = {
          pyright = {
            name = 'gh act -j pyright',
            builder = function()
              return {
                cmd = { 'act' },
                args = { '-j', 'pyright' },
                name = 'act -j pyright',
                cwd = config.dirs.work.airflow_pipeline,
                components = { 'default' },
              }
            end,
            desc = 'run pyright checks with act',
            condition = {
              dir = config.dirs.work.airflow_pipeline,
            },
          },
        },
      }

      overseer.register_template(templates.edge_server.test)
      overseer.register_template(templates.edge_server.lint)
      overseer.register_template(templates.airflow_pipeline.pyright)

      vim.api.nvim_create_autocmd('FileType', {
        pattern = 'OverseerOutput',
        callback = function()
          vim.api.nvim_buf_set_keymap(0, 'n', 'gf', ':lua lib.fs.open_file_in("top_split")<CR>', {
            desc = 'overseer: open file in top split',
          })
        end,
      })
    end,
    -- stylua: ignore
    keys = {
      -- { "<leader>OR", "<cmd>OverseerRun<cr>",         desc = "Overseer: Run task" },
      { "<leader>run", "<cmd>OverseerRun<cr>", desc = "Overseer: Run task" },
      { "♥", "<cmd>OverseerToggle<cr>", desc = "Overseer: Toggle" }, -- C-S-R set in terminal
      -- { "<C-]>", "<cmd>OverseerToggle<cr>",      desc = "Overseer: Toggle" },
      { "<leader>OQ", "<cmd>OverseerQuickAction<cr>", desc = "Overseer: Action recent task" },
      { "<leader>OI", "<cmd>OverseerInfo<cr>", desc = "Overseer: Overseer Info" },
      { "<leader>OB", "<cmd>OverseerBuild<cr>", desc = "Overseer: Task builder" },
      { "<leader>OA", "<cmd>OverseerTaskAction<cr>", desc = "Overseer: Task action" },
      { "<leader>OC", "<cmd>OverseerClearCache<cr>", desc = "Overseer: Clear cache" },
    },
  },
}
