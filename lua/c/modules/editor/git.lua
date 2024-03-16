return {
  { -- Adds git related signs to the gutter, as well as utilities for managing changes
    'lewis6991/gitsigns.nvim',
    opts = {
      signs = {
        add = { text = '+' },
        change = { text = '~' },
        delete = { text = '_' },
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
        map({ "n", "v" }, "<leader>gs", ":Gitsigns stage_hunk<CR>", "Stage Hunk")
        map("n", "<leader>gu", gs.undo_stage_hunk, "Undo Stage Hunk")
        map({ "n", "v" }, "<leader>gr", ":Gitsigns reset_hunk<CR>", "Reset Hunk")
        map("n", "<leader>gS", gs.stage_buffer, "Stage Buffer")
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
    'NeogitOrg/neogit',
    dependencies = {
      'nvim-lua/plenary.nvim', -- required
      'sindrets/diffview.nvim', -- optional - Diff integration
      'nvim-telescope/telescope.nvim', -- optional
    },
    config = function()
      require('neogit').setup {}

      local neogit_group = vim.api.nvim_create_augroup('ColorschemeGroup', { clear = true })
      vim.api.nvim_create_autocmd({ 'BufEnter' }, {
        pattern = { 'NeogitStatus' },
        callback = function()
          vim.cmd.colorscheme(vim.g.pretty_colorscheme)
        end,
        group = neogit_group,
        desc = 'Run when opening Neogit',
      })

      vim.api.nvim_create_autocmd({ 'BufWinLeave' }, {
        pattern = { 'NeogitStatus' },
        callback = function()
          vim.cmd.colorscheme(vim.g.code_colorscheme)
        end,
        group = neogit_group,
        desc = 'Run when opening Neogit',
      })

      vim.api.nvim_create_autocmd({ 'FileType' }, {
        pattern = 'DiffviewFiles',
        group = neogit_group,
        desc = 'Run when entering diff view',
        callback = function()
          vim.cmd.colorscheme(vim.g.code_colorscheme)
        end,
      })
    end,
    keys = { { '<leader>gg', ':Neogit<CR>', desc = 'Neogit' } },
  },
}
