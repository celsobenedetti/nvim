return {
  'nvim-neo-tree/neo-tree.nvim',
  lazy = true,
  cmd = 'Neotree',
  -- enabled = false, -- trying out the new snacks.nvim explorer instead
  keys = {
    -- {
    --   '<leader>e',
    --   function()
    --     require('neo-tree.command').execute { toggle = true }
    --   end,
    --   desc = 'Explorer NeoTree (Root Dir)',
    -- },
    {
      '<leader>fe',
      function()
        require('neo-tree.command').execute { toggle = true, dir = vim.uv.cwd(), position = 'left' }
      end,
      desc = 'Explorer NeoTree (cwd)',
    },
    {
      '<leader>fE',
      function()
        require('neo-tree.command').execute { toggle = true, dir = vim.uv.cwd(), position = 'right' }
      end,
      desc = 'Explorer NeoTree (cwd)',
    },

    -- NOTE: (neotree) Buffer Explorer: Maybe this is useful
    {
      '<leader>be',
      function()
        require('neo-tree.command').execute { source = 'buffers', toggle = true }
      end,
      desc = 'Buffer Explorer',
    },
  },
  deactivate = function()
    vim.cmd [[Neotree close]]
  end,
  init = function()
    -- LazyVim explains how this needs to be setup in autocmd because of cwd setup issue whe lazy loading
    vim.api.nvim_create_autocmd('BufEnter', {
      group = vim.api.nvim_create_augroup('Neotree_start_directory', { clear = true }),
      desc = 'Start Neo-tree with directory',
      once = true,
      callback = function()
        if package.loaded['neo-tree'] then
          return
        else
          ---@diagnostic disable-next-line: param-type-mismatch
          local stats = vim.uv.fs_stat(vim.fn.argv(0))
          if stats and stats.type == 'directory' then
            require 'neo-tree'
          end
        end
      end,
    })
  end,
  config = function(_, _)
    local opts = {
      sources = { 'filesystem', 'buffers', 'git_status' },
      open_files_do_not_replace_types = { 'terminal', 'Trouble', 'trouble', 'qf', 'Outline' },
      filesystem = {
        bind_to_cwd = false,
        follow_current_file = { enabled = true },
        use_libuv_file_watcher = true,
        components = {
          harpoon_index = function(config, node, _)
            local harpoon_list = require('harpoon'):list()
            local path = node:get_id()
            local harpoon_key = vim.uv.cwd()

            for i, item in ipairs(harpoon_list.items) do
              local value = item.value
              if string.sub(item.value, 1, 1) ~= '/' then
                value = harpoon_key .. '/' .. item.value
              end

              if value == path then
                return {
                  text = string.format(' 󰛢 ⥤ %d', i), -- <-- Add your favorite harpoon like arrow here
                  highlight = config.highlight or 'NeoTreeDirectoryIcon',
                }
              end
            end
            return {}
          end,
        },
        renderers = {
          file = {
            { 'icon' },
            { 'name', use_git_status_colors = true },
            { 'harpoon_index' }, --> This is what actually adds the Harpoon component in where you want it
            { 'diagnostics' },
            { 'git_status', highlight = 'NeoTreeDimText' },
          },
        },
      },
      window = {
        position = 'current',
        mappings = {
          ['l'] = 'open',
          ['h'] = 'close_node',
          ['<space>'] = 'none',
          ['Y'] = {
            function(state)
              local node = state.tree:get_node()
              local path = node:get_id()
              vim.fn.setreg('+', path, 'c')
            end,
            desc = 'Copy Path to Clipboard',
          },
          ['O'] = {
            function(state)
              require('lazy.util').open(state.tree:get_node().path, { system = true })
            end,
            desc = 'Open with System Application',
          },
          ['P'] = { 'toggle_preview', config = { use_float = false } },
        },
      },
      default_component_configs = {
        indent = {
          with_expanders = true, -- if nil and file nesting is enabled, will enable expanders
          expander_collapsed = '',
          expander_expanded = '',
          expander_highlight = 'NeoTreeExpander',
        },
        git_status = {
          symbols = {
            unstaged = '󰄱',
            staged = '󰱒',
          },
        },
      },
      -- ~/.local/share/nvim/lazy/neo-tree.nvim/lua/neo-tree/events/init.lua
      event_handlers = {
        {
          event = 'neo_tree_buffer_enter',
          handler = function(_arg)
            vim.opt.relativenumber = true
          end,
        },
        {
          event = 'file_moved',
          handler = function(data)
            Snacks.rename.on_rename_file(data.source, data.destination)
          end,
        },
        {
          event = 'file_renamed',
          handler = function(data)
            Snacks.rename.on_rename_file(data.source, data.destination)
          end,
        },
      },
    }
    require('neo-tree').setup(opts)

    vim.api.nvim_create_autocmd('TermClose', {
      pattern = '*lazygit',
      callback = function()
        if package.loaded['neo-tree.sources.git_status'] then
          require('neo-tree.sources.git_status').refresh()
        end
      end,
    })
  end,
}
