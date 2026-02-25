local notes = require('lib.notes')

vim.keymap.set('n', vim.g.mappings.ghostty['<C-S-N>'], function()
  notes.focus_or_create_notes_tab(function()
    notes.grep({
      cwd = vim.g.env.notes.NOTES,
      cmd = {
        'rg',
        '--no-heading',
        '--line-number',
        -- '-g',
        -- '!' .. vim.g.env.notes.ASSETS_DIR .. '/*',
        '-v',
        vim.g.env.notes.GREP_IGNORE, -- No quotes needed here!
        vim.g.env.notes.NOTES,
      },
    })
  end)
end, { desc = 'search all notes' })
