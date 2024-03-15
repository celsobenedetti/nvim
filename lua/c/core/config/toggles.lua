--- toggles

local copilot = vim.g.copilot
local completion = vim.g.completion
local diagnostics = vim.g.diagnostics
local conceallevel = vim.o.conceallevel > 0 and vim.o.conceallevel or 3

--- Functions for each toggle
local toggles = {

  -- toggle autoformat
  format = function()
    vim.g.autoformat = not vim.g.autoformat
    print('Autoformat: ' .. tostring(vim.g.autoformat))
  end,

  -- toggle copilot
  copilot = function()
    if copilot then
      vim.api.nvim_command 'Copilot disable'
    else
      vim.api.nvim_command 'Copilot start'
    end
    copilot = not copilot
  end,

  -- completion
  completion = function()
    local cmp = require 'cmp'
    local augroupName = 'cmp-augroup'
    local toggle_completion = function(is_enabled)
      cmp.setup.buffer { enabled = is_enabled }
    end

    completion = not completion
    toggle_completion(completion)

    if completion then
      print 'Enabled completion (cmp)'
      vim.api.nvim_clear_autocmds { group = augroupName }
    else
      vim.api.nvim_create_autocmd('BufEnter', {
        desc = ('Disable completion: %s'):format 'BufEnter',
        group = vim.api.nvim_create_augroup(augroupName, { clear = true }),
        callback = function()
          toggle_completion(false)
        end,
      })
      print 'Disabled completion (cmp)'
    end
  end,

  -- toggle LSP diagnostics
  diagnostics = function()
    if diagnostics then
      vim.diagnostic.disable()
      print 'Disabled diagnostics'
    else
      vim.diagnostic.enable()
      print 'Enabled diagnostics'
    end
    diagnostics = not diagnostics
  end,

  -- Toggle nvim options:
  -- returns a function callback to toggle
  --
  -- spell, conceallevel, etc
  option = function(opts)
    return function()
      local option = opts.option
      local silent = opts.silent
      local values = opts.values

      if values then
        if vim.opt_local[option]:get() == values[1] then
          ---@diagnostic disable-next-line: no-unknown
          vim.opt_local[option] = values[2]
        else
          ---@diagnostic disable-next-line: no-unknown
          vim.opt_local[option] = values[1]
        end
        return print('Set ' .. option .. ' to ' .. vim.opt_local[option]:get())
      end
      ---@diagnostic disable-next-line: no-unknown
      vim.opt_local[option] = not vim.opt_local[option]:get()
      if not silent then
        if vim.opt_local[option]:get() then
          print('Enabled ' .. option)
        else
          print('Disabled ' .. option)
        end
      end
    end
  end,
}

map('n', '<leader>uf', toggles.format, { desc = 'Toggle auto format (global)' })
map('n', '<leader>uc', toggles.completion, { desc = 'Toggle completion' })
map('n', '<leader>uC', toggles.copilot, { desc = 'Toggle diagnostics' })
map('n', '<leader>ud', toggles.diagnostics, { desc = 'Toggle diagnostics' })

map('n', '<leader>us', toggles.option { option = 'spell' }, { desc = 'Toggle Spelling' })
map('n', '<leader>tc', toggles.option { option = 'conceallevel', silent = false, values = { 0, conceallevel } }, { desc = 'Toggle diagnostics' })
