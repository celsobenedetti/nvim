local notes = require('lib.notes')

vim.keymap.set('n', vim.g.key.ghostty['<C-S-N>'], function()
  notes.focus_or_create_notes_tab(function()
    notes.grep({
      cwd = vim.g.env.notes.NOTES,
      cmd = {
        'rg',
        '--no-heading',
        '--line-number',
        '-v',
        string.format('"%s"', vim.g.env.notes.GREP_IGNORE), -- quotes are indeed needed here for complex regex
        vim.g.env.notes.NOTES,
      },
    })
  end)
end, { desc = 'search all notes' })
