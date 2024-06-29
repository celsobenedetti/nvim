local is_diffview_open = false

local is_conflict_enabled = true

return {

  { -- Adds git related signs to the gutter, as well as utilities for managing changes
    'lewis6991/gitsigns.nvim',
    opts = {
      signs = {
        add = { text = '│ ' },
        change = { text = '~' },
        delete = { text = '' },
        topdelete = { text = '‾' },
        changedelete = { text = '~' },
      },

      on_attach = function(buffer)
        local gs = package.loaded.gitsigns

        local function map(mode, l, r, desc)
          vim.keymap.set(mode, l, r, { buffer = buffer, desc = desc })
        end

        -- stylua: ignore start
        map("n", "]h", gs.next_hunk, "Next Hunk")
        map("n", "[h", gs.prev_hunk, "Prev Hunk")
        map("n", "<leader>gu", gs.undo_stage_hunk, "Undo Stage Hunk")
        map({ "n", "v" }, "<leader>ga", ":Gitsigns stage_hunk<CR>", "Stage Hunk")
        map("n", "<leader>gA", gs.stage_buffer, "Stage Buffer")
        map({ "n", "v" }, "<leader>gr", ":Gitsigns reset_hunk<CR>", "Reset Hunk")
        map("n", "<leader>gR", gs.reset_buffer, "Reset Buffer")
        map("n", "<leader>gp", gs.preview_hunk_inline, "Preview Hunk Inline")
        map("n", "<leader>gb", function() gs.blame_line({ full = true }) end, "Blame Line")
        map("n", "<leader>gd", gs.diffthis, "Diff This")
        map("n", "<leader>gD", function() gs.diffthis("~") end, "Diff This ~")
        map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", "GitSigns Select Hunk")
      end,
    },
  },
  {
    'sindrets/diffview.nvim',
    keys = {
      {
        '<leader>D',
        function()
          if is_diffview_open then
            is_diffview_open = false
            require('diffview').close()
          else
            is_diffview_open = true
            require('diffview').open()
          end
        end,
        desc = 'Toggle Diffview',
      },
    },
  },

  {
    'akinsho/git-conflict.nvim',
    version = '*',
    enabled = is_conflict_enabled,
    config = function()
      require('git-conflict').setup {
        default_mappings = false,
      }

      vim.keymap.set('n', '<leader>co', ':GitConflictChooseOurs<CR>')
      vim.keymap.set('n', '<leader>ct', ':GitConflictChooseTheirs<CR>')
      vim.keymap.set('n', '<leader>cb', ':GitConflictChooseBoth<CR>')
      vim.keymap.set('n', '<leader>c0', ':GitConflictChooseNone<CR>')
      vim.keymap.set('n', '[x', ':GitConflictPrevConflict<CR>')
      vim.keymap.set('n', ']x', ':GitConflictNextConflict<CR>')
    end,
  },
  {
    'pwntester/octo.nvim',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-telescope/telescope.nvim',
      'nvim-tree/nvim-web-devicons',
    },
    cmd = { 'Octo' },
    config = function()
      require('octo').setup()
    end,
  },
}
